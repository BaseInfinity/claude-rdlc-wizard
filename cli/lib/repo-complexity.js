// Research-repo complexity heuristic for rdlc-wizard.
//
// Output: { tier: 'simple' | 'complex', score: <number>, signals: [...] }
//   - 'simple' → suggests a lighter setup (single deliverable, fewer audiences)
//   - 'complex' → suggests full RDLC stack (multi-deliverable, multi-audience, multi-source)
//
// Signals (mirrors RDLC's evidence/output/audiences taxonomy, not SDLC's loc/tests):
//   deliverables — count of files in output/
//   evidence_dirs — count of subdirs under evidence/
//   research_files — count of files in research/
//   sources — count of files in sources/ (raw source artifacts)
//   audiences — count of distinct audience targets (audience-firewall.conf entries)
//
// Stakes-equivalent override:
//   PII / sensitive raw data hits → forces 'complex' tier regardless of score
//
// Heuristic is intentionally cheap: a single sync filesystem walk, no parsing.

const fs = require('fs');
const path = require('path');

const SKIP_DIRS = new Set([
  'node_modules', '.git', 'dist', 'build', 'out', 'target',
  '.next', '.nuxt', 'coverage', '.cache', 'vendor', '__pycache__',
]);

const STAKES_FILES = new Set(['.env', '.env.local', 'PII.md', 'subjects.csv']);
const STAKES_DIRS = new Set(['raw_pii', 'subjects', 'interviews_raw']);

function walk(rootDir, onFile, onDir, visited) {
  let entries;
  try {
    entries = fs.readdirSync(rootDir, { withFileTypes: true });
  } catch (_) {
    return;
  }
  for (const entry of entries) {
    const full = path.join(rootDir, entry.name);
    if (entry.isSymbolicLink()) continue;
    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue;
      let realPath;
      try {
        realPath = fs.realpathSync(full);
      } catch (_) {
        continue;
      }
      if (visited.has(realPath)) continue;
      visited.add(realPath);
      onDir && onDir(full, entry.name);
      walk(full, onFile, onDir, visited);
    } else if (entry.isFile()) {
      onFile(full, entry.name, path.basename(rootDir));
    }
  }
}

function countAudiences(repoRoot) {
  const conf = path.join(repoRoot, '.rdlc', 'audience-firewall.conf');
  if (!fs.existsSync(conf)) return 0;
  try {
    const lines = fs.readFileSync(conf, 'utf8').split('\n')
      .map((l) => l.trim())
      .filter((l) => l && !l.startsWith('#'));
    return lines.length;
  } catch (_) {
    return 0;
  }
}

function detectComplexity(repoPath) {
  if (!fs.existsSync(repoPath)) {
    throw new Error(`Repo path does not exist: ${repoPath}`);
  }
  const stat = fs.statSync(repoPath);
  if (!stat.isDirectory()) {
    throw new Error(`Repo path is not a directory: ${repoPath}`);
  }
  const repoRoot = path.resolve(repoPath);

  let deliverables = 0;
  let evidenceDirs = 0;
  let researchFiles = 0;
  let sources = 0;
  const stakesHits = [];
  const visited = new Set([fs.realpathSync(repoRoot)]);

  walk(
    repoRoot,
    (filePath, name, parent) => {
      const rel = path.relative(repoRoot, filePath);
      if (STAKES_FILES.has(name)) {
        stakesHits.push(`stakes:file:${rel}`);
      }
      if (parent === 'output' && filePath.includes(`${path.sep}output${path.sep}`)) {
        deliverables++;
      }
      // v0.3.2: also count root-level *.md files that have a paired *.html or
      // *.pdf alongside (e.g., tucson-investigation has car_report.{md,html,pdf}
      // at root, never created an output/ dir). The render-pairing pattern is
      // a strong "deliverable" signal regardless of directory location.
      const ext = path.extname(name);
      if (
        ext === '.md' &&
        path.dirname(rel) === '.' &&
        !/^(README|CHANGELOG|CLAUDE|SDLC|RDLC|ARCHITECTURE|ROADMAP|TESTING|AGENTS|HANDOFF|PATTERNS|EXTRACTION_NOTES|WIZARD_PLAN|CASE_STUDIES|CONTRIBUTING|CI_CD|CODEX_.*|SCORE_TRENDS|COMPETITIVE_AUDIT|CODE_REVIEW_EXCEPTIONS|RESEARCH_.*|AUTOCOMPACT_BENCHMARK|ISSUES_FOUND_BY_CODEX|BRANDING)\.md$/i.test(name)
      ) {
        const stem = name.slice(0, -3);
        const htmlPair = path.join(repoRoot, stem + '.html');
        const pdfPair = path.join(repoRoot, stem + '.pdf');
        if (fs.existsSync(htmlPair) || fs.existsSync(pdfPair)) {
          deliverables++;
        }
      }
      if (parent === 'research' && filePath.includes(`${path.sep}research${path.sep}`)) {
        researchFiles++;
      }
      if (parent === 'sources' && filePath.includes(`${path.sep}sources${path.sep}`)) {
        sources++;
      }
    },
    (dirPath, name) => {
      if (STAKES_DIRS.has(name)) {
        const rel = path.relative(repoRoot, dirPath);
        stakesHits.push(`stakes:dir:${rel || name}/`);
      }
      const parent = path.basename(path.dirname(dirPath));
      if (parent === 'evidence') {
        evidenceDirs++;
      }
    },
    visited
  );

  const audiences = countAudiences(repoRoot);

  const signals = [];
  let highHits = 0;
  let score = 0;

  function band(value, midThreshold, highThreshold, label) {
    if (value >= highThreshold) {
      score += 2;
      highHits++;
      signals.push(`${label}:${value} (high → +2)`);
    } else if (value >= midThreshold) {
      score += 1;
      signals.push(`${label}:${value} (mid → +1)`);
    } else {
      signals.push(`${label}:${value} (low → +0)`);
    }
  }

  band(deliverables, 2, 5, 'deliverables');
  band(evidenceDirs, 2, 5, 'evidence_dirs');
  band(researchFiles, 5, 20, 'research_files');
  band(sources, 5, 20, 'sources');
  band(audiences, 2, 4, 'audiences');

  let tier = highHits > 0 ? 'complex' : 'simple';
  if (stakesHits.length > 0) {
    tier = 'complex';
    signals.push(...stakesHits, 'override:stakes-forces-complex');
  }

  return { tier, score, signals };
}

module.exports = { detectComplexity };

if (require.main === module) {
  const target = process.argv[2] || '.';
  try {
    const result = detectComplexity(target);
    process.stdout.write(JSON.stringify(result, null, 2) + '\n');
  } catch (err) {
    process.stderr.write(`error: ${err.message}\n`);
    process.exit(2);
  }
}
