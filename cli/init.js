'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const RESET = '\x1b[0m';
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const MAGENTA = '\x1b[35m';
const CYAN = '\x1b[36m';

const REPO_ROOT = path.join(__dirname, '..');
const TEMPLATES_DIR = path.join(__dirname, 'templates');
const RDLC_DOC = path.join(REPO_ROOT, 'RDLC.md');
const PRESETS_DIR = path.join(REPO_ROOT, 'presets');

// v0.6: presets. Auto-detected from scanResearch().recommended_domain unless the
// user passes --preset explicitly. The general-research "preset" is the base
// RDLC.md — no override needed.
function listAvailablePresets() {
  if (!fs.existsSync(PRESETS_DIR)) return [];
  return fs.readdirSync(PRESETS_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory() && fs.existsSync(path.join(PRESETS_DIR, d.name, 'RDLC.md')))
    .map((d) => d.name);
}

function presetRdlcPath(presetName) {
  return path.join(PRESETS_DIR, presetName, 'RDLC.md');
}

function resolvePreset(targetDir, explicitPreset) {
  // Explicit --preset overrides auto-detect. general-research means "use base".
  if (explicitPreset) {
    if (explicitPreset === 'general-research') return null;
    const available = listAvailablePresets();
    if (!available.includes(explicitPreset)) {
      const err = new Error(
        `Unknown preset: "${explicitPreset}". Available: ${available.join(', ') || '(none)'}, general-research`
      );
      err.code = 'UNKNOWN_PRESET';
      throw err;
    }
    return explicitPreset;
  }
  // Auto-detect via the scanner. Fall back to base on any error.
  try {
    const { scanResearch } = require('./lib/scan-research');
    const result = scanResearch(targetDir);
    const recommended = result.recommended_domain;
    if (recommended && recommended !== 'general-research') {
      const available = listAvailablePresets();
      if (available.includes(recommended)) return recommended;
    }
  } catch (_) {
    // Scanner failure shouldn't break install — just use base.
  }
  return null;
}

// Skills + hooks live at repo root (single source of truth for both plugin and CLI).
// Only settings.json lives in cli/templates/ — it's the CLI-install-specific hook config.
const FILES = [
  { src: 'settings.json', dest: '.claude/settings.json', base: TEMPLATES_DIR },

  { src: 'hooks/_find-rdlc-root.sh', dest: '.claude/hooks/_find-rdlc-root.sh', executable: true, base: REPO_ROOT },
  { src: 'hooks/rdlc-prompt-check.sh', dest: '.claude/hooks/rdlc-prompt-check.sh', executable: true, base: REPO_ROOT },
  { src: 'hooks/slop-scan-pretool.sh', dest: '.claude/hooks/slop-scan-pretool.sh', executable: true, base: REPO_ROOT },
  { src: 'hooks/confidence-required.sh', dest: '.claude/hooks/confidence-required.sh', executable: true, base: REPO_ROOT },
  { src: 'hooks/source-required.sh', dest: '.claude/hooks/source-required.sh', executable: true, base: REPO_ROOT },
  { src: 'hooks/audience-firewall.sh', dest: '.claude/hooks/audience-firewall.sh', executable: true, base: REPO_ROOT },
  { src: 'hooks/rdlc-instructions-check.sh', dest: '.claude/hooks/rdlc-instructions-check.sh', executable: true, base: REPO_ROOT },

  { src: 'skills/rdlc/SKILL.md', dest: '.claude/skills/rdlc/SKILL.md', base: REPO_ROOT },
  { src: 'skills/setup/SKILL.md', dest: '.claude/skills/setup/SKILL.md', base: REPO_ROOT },
  { src: 'skills/update/SKILL.md', dest: '.claude/skills/update/SKILL.md', base: REPO_ROOT },
  { src: 'skills/feedback/SKILL.md', dest: '.claude/skills/feedback/SKILL.md', base: REPO_ROOT },

  // v0.3.2: scripts/ and .rdlc/ — previously the /setup skill expected to copy
  // these from `${CLAUDE_PLUGIN_ROOT}/templates/`, which doesn't resolve for CLI
  // installs. Now `init` drops them directly. Templates carry TODO markers; the
  // /setup skill walks the user through customizing them in Step 7.
  { src: 'templates/regression_test.sh.template', dest: 'scripts/regression_test.sh', executable: true, base: REPO_ROOT },
  { src: 'templates/slop_scan.sh.template', dest: 'scripts/slop_scan.sh', executable: true, base: REPO_ROOT },
  { src: 'templates/generate_deliverable.py.template', dest: 'scripts/generate_deliverable.py', base: REPO_ROOT },
  { src: 'templates/slop-allowlist.txt.template', dest: '.rdlc/slop-allowlist.txt', base: REPO_ROOT },
];

const WIZARD_HOOK_MARKERS = FILES
  .filter((f) => f.executable && f.dest.startsWith('.claude/hooks/'))
  .map((f) => path.basename(f.src));

const GITIGNORE_ENTRIES = ['.claude/plans/', '.claude/settings.local.json'];

function isWizardHookEntry(hookEntry) {
  if (!hookEntry || !hookEntry.hooks) return false;
  return hookEntry.hooks.some((h) =>
    WIZARD_HOOK_MARKERS.some((marker) => h.command && h.command.includes(marker))
  );
}

function mergeSettings(existingPath, templatePath, force) {
  try {
    const existing = JSON.parse(fs.readFileSync(existingPath, 'utf8'));
    const template = JSON.parse(fs.readFileSync(templatePath, 'utf8'));

    if ('cleanupPeriodDays' in template && !('cleanupPeriodDays' in existing)) {
      existing.cleanupPeriodDays = template.cleanupPeriodDays;
    }

    if (!existing.hooks) existing.hooks = {};

    for (const [event, templateEntries] of Object.entries(template.hooks || {})) {
      if (!existing.hooks[event]) {
        existing.hooks[event] = templateEntries;
        continue;
      }

      const templateEntry = templateEntries[0];
      const existingIdx = existing.hooks[event].findIndex(isWizardHookEntry);

      if (existingIdx === -1) {
        existing.hooks[event].push(templateEntry);
      } else if (force) {
        existing.hooks[event][existingIdx] = templateEntry;
      }
    }

    const merged = JSON.stringify(existing, null, 2) + '\n';
    const original = fs.readFileSync(existingPath, 'utf8');
    return merged === original ? null : merged;
  } catch (_) {
    return null;
  }
}

function planOperations(targetDir, { force, preset }) {
  const ops = [];

  for (const file of FILES) {
    const destPath = path.join(targetDir, file.dest);
    const srcPath = path.join(file.base || TEMPLATES_DIR, file.src);
    const exists = fs.existsSync(destPath);

    if (exists && file.dest === '.claude/settings.json') {
      const merged = mergeSettings(destPath, srcPath, force);
      if (merged) {
        ops.push({
          src: srcPath,
          dest: destPath,
          relativeDest: file.dest,
          action: 'MERGE',
          mergedContent: merged,
          executable: false,
        });
        continue;
      }
    }

    ops.push({
      src: srcPath,
      dest: destPath,
      relativeDest: file.dest,
      action: exists ? (force ? 'OVERWRITE' : 'SKIP') : 'CREATE',
      executable: file.executable || false,
    });
  }

  // RDLC.md canonical — preset variant if one resolved, else base canonical
  const rdlcSrc = preset ? presetRdlcPath(preset) : RDLC_DOC;
  const rdlcDest = path.join(targetDir, 'RDLC.md');
  const rdlcExists = fs.existsSync(rdlcDest);
  const rdlcLabel = preset ? `RDLC.md (preset: ${preset})` : 'RDLC.md';
  ops.push({
    src: rdlcSrc,
    dest: rdlcDest,
    relativeDest: rdlcLabel,
    action: rdlcExists ? (force ? 'OVERWRITE' : 'SKIP') : 'CREATE',
    executable: false,
  });

  return ops;
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function executeOperations(ops) {
  for (const op of ops) {
    if (op.action === 'SKIP') continue;
    ensureDir(op.dest);
    if (op.action === 'MERGE') {
      fs.writeFileSync(op.dest, op.mergedContent);
    } else {
      fs.copyFileSync(op.src, op.dest);
    }
    if (op.executable) {
      fs.chmodSync(op.dest, 0o755);
    }
  }
}

function updateGitignore(targetDir, { dryRun }) {
  const gitignorePath = path.join(targetDir, '.gitignore');
  let content = '';
  if (fs.existsSync(gitignorePath)) {
    content = fs.readFileSync(gitignorePath, 'utf8');
  }

  const lines = content.split('\n').map((l) => l.trim()).filter((l) => l && !l.startsWith('#'));
  const toAdd = GITIGNORE_ENTRIES.filter((entry) => !lines.includes(entry));
  if (toAdd.length === 0) return [];

  if (!dryRun) {
    const suffix = (content && !content.endsWith('\n') ? '\n' : '') + toAdd.join('\n') + '\n';
    fs.appendFileSync(gitignorePath, suffix);
  }

  return toAdd;
}

function printOps(ops) {
  for (const op of ops) {
    const color = op.action === 'CREATE' ? GREEN
      : op.action === 'SKIP' ? YELLOW
      : op.action === 'MERGE' ? MAGENTA
      : CYAN;
    console.log(`  ${color}${op.action}${RESET}  ${op.relativeDest}`);
  }
}

// .rdlc/version is dynamic (always reflects the current wizard version), so it
// lives outside FILES and gets written separately. /update uses this file as a
// quick drift check independent of the RDLC.md metadata header.
function writeVersionFile(targetDir, force) {
  const versionPath = path.join(targetDir, '.rdlc', 'version');
  const exists = fs.existsSync(versionPath);
  const wizardVersion = require('../package.json').version;
  if (exists && !force) {
    return { action: 'SKIP', relativeDest: '.rdlc/version' };
  }
  fs.mkdirSync(path.dirname(versionPath), { recursive: true });
  fs.writeFileSync(versionPath, wizardVersion + '\n');
  return { action: exists ? 'OVERWRITE' : 'CREATE', relativeDest: '.rdlc/version' };
}

function init(targetDir, { force = false, dryRun = false, preset = null } = {}) {
  // Resolve preset (explicit overrides auto-detect). Throws UNKNOWN_PRESET if
  // the user passed --preset with an unknown name — caller decides how to surface.
  const resolvedPreset = resolvePreset(targetDir, preset);
  const ops = planOperations(targetDir, { force, preset: resolvedPreset });

  if (dryRun) {
    console.log('Dry run — no files will be written:\n');
    if (resolvedPreset) {
      console.log(`  ${MAGENTA}Preset:${RESET} ${resolvedPreset}${preset ? ' (explicit)' : ' (auto-detected)'}\n`);
    }
    printOps(ops);
    const versionExists = fs.existsSync(path.join(targetDir, '.rdlc', 'version'));
    const versionAction = versionExists ? (force ? 'OVERWRITE' : 'SKIP') : 'CREATE';
    printOps([{ action: versionAction, relativeDest: '.rdlc/version' }]);
    const gitignoreAdds = updateGitignore(targetDir, { dryRun: true });
    if (gitignoreAdds.length > 0) {
      console.log(`  ${GREEN}APPEND${RESET}  .gitignore (${gitignoreAdds.join(', ')})`);
    }
    return true;
  }

  console.log('');
  if (resolvedPreset) {
    console.log(`  ${MAGENTA}Preset:${RESET} ${resolvedPreset}${preset ? ' (explicit)' : ' (auto-detected from research signals)'}\n`);
  }
  printOps(ops);

  const versionOp = writeVersionFile(targetDir, force);
  printOps([versionOp]);

  if (ops.every((o) => o.action === 'SKIP') && versionOp.action === 'SKIP') {
    console.log('\nAll files already exist. Use --force to overwrite.');
    return true;
  }

  executeOperations(ops);

  const gitignoreAdds = updateGitignore(targetDir, { dryRun: false });
  if (gitignoreAdds.length > 0) {
    console.log(`  ${GREEN}APPEND${RESET}  .gitignore (${gitignoreAdds.join(', ')})`);
  }

  console.log(`
${GREEN}RDLC Wizard installed successfully!${RESET}

${YELLOW}Restart Claude Code${RESET} to load new hooks and skills:
  ${CYAN}/exit${RESET} then ${CYAN}claude --continue${RESET}  (keeps conversation history)
  ${CYAN}/exit${RESET} then ${CYAN}claude${RESET}              (fresh start)

Next steps:
  1. Restart Claude Code (see above)
  2. Run ${CYAN}/setup${RESET} to configure RDLC for your research domain
  3. The wizard reads RDLC.md to understand what's enforced

The canonical doc is at: RDLC.md
  `);

  return true;
}

function checkFile(srcPath, destPath, relativeDest, shouldBeExecutable) {
  if (!fs.existsSync(destPath)) {
    return { file: relativeDest, status: 'MISSING' };
  }
  const srcHash = crypto.createHash('sha256').update(fs.readFileSync(srcPath)).digest('hex');
  const destHash = crypto.createHash('sha256').update(fs.readFileSync(destPath)).digest('hex');
  const result = {
    file: relativeDest,
    status: srcHash === destHash ? 'MATCH' : 'CUSTOMIZED',
  };

  if (shouldBeExecutable) {
    try {
      fs.accessSync(destPath, fs.constants.X_OK);
    } catch (_) {
      result.status = 'DRIFT';
      result.details = 'Missing executable permission (chmod +x)';
    }
  }

  return result;
}

function checkGitignore(gitignorePath) {
  if (!fs.existsSync(gitignorePath)) {
    return { file: '.gitignore', status: 'MISSING', details: 'No .gitignore found' };
  }
  const lines = fs.readFileSync(gitignorePath, 'utf8').split('\n')
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith('#'));
  const missing = GITIGNORE_ENTRIES.filter((e) => !lines.includes(e));
  if (missing.length > 0) {
    return { file: '.gitignore', status: 'DRIFT', details: `Missing entries: ${missing.join(', ')}` };
  }
  return { file: '.gitignore', status: 'MATCH' };
}

function check(targetDir, { json = false } = {}) {
  const results = [];

  for (const file of FILES) {
    const destPath = path.join(targetDir, file.dest);
    const srcPath = path.join(file.base || TEMPLATES_DIR, file.src);
    results.push(checkFile(srcPath, destPath, file.dest, file.executable || false));
  }

  const rdlcDest = path.join(targetDir, 'RDLC.md');
  results.push(checkFile(RDLC_DOC, rdlcDest, 'RDLC.md', false));

  const gitignorePath = path.join(targetDir, '.gitignore');
  results.push(checkGitignore(gitignorePath));

  let updateInfo = null;
  try {
    const { execSync } = require('child_process');
    const latest = execSync('npm view claude-rdlc-wizard version 2>/dev/null', {
      encoding: 'utf8',
      timeout: 5000,
    }).trim();
    const current = require('../package.json').version;
    if (latest && latest !== current) {
      updateInfo = { current, latest };
    }
  } catch (_) {
    // Offline or npm unavailable — skip update check
  }

  const hasDrift = results.some((r) => r.status === 'MISSING' || r.status === 'DRIFT');

  if (json) {
    console.log(JSON.stringify({ files: results, update: updateInfo }, null, 2));
  } else {
    for (const r of results) {
      const color = r.status === 'MATCH' ? GREEN : r.status === 'MISSING' ? RED : YELLOW;
      console.log(`  ${color}${r.status}${RESET}  ${r.file}`);
      if (r.details) console.log(`         ${r.details}`);
    }
    if (updateInfo) {
      console.log(`\n  ${YELLOW}UPDATE${RESET}  v${updateInfo.current} -> v${updateInfo.latest}`);
      console.log('         Run: npx claude-rdlc-wizard init --force');
    }
  }

  return { results, updateInfo, hasDrift };
}

module.exports = { init, check, planOperations, listAvailablePresets, GITIGNORE_ENTRIES };
