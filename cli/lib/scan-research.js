// v0.3 setup-scan refinement: signals the /setup skill consumes via
// `npx claude-rdlc-wizard scan --json`. Replaces the v0.1 narrative
// "look for these directories" with a concrete signal-counting pass.
//
// Output:
//   {
//     domain: { 'medical-legal': N, 'political-research': N,
//               'automotive-audit': N, 'general-research': N },
//     recommended_domain: '<highest-scoring or general-research>',
//     confidence_labels: { VERIFIED, SUPPORTED, INFERRED, UNVERIFIED,
//                          GAP, DIRECT, convention_in_use },
//     tooling: { sdlc_wizard, codex, regression_test, slop_scan,
//                agents_md, claude_md, rdlc_md },
//     structure: { has_evidence, has_research, has_sources,
//                  has_output, has_reviews, has_scripts }
//   }

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const SKIP_DIRS = new Set([
  'node_modules', '.git', 'dist', 'build', 'out', 'target',
  '.next', '.nuxt', 'coverage', '.cache', 'vendor', '__pycache__',
]);

// Domain pattern definitions: each pattern hit on file *content* or path adds 1
// to the matching domain's score. General-research gets a baseline of 1 so it
// wins ties (the safe default for unfamiliar repos).
const DOMAIN_PATTERNS = {
  'medical-legal': {
    pathSubstrings: ['evidence/team_profiles', 'clinical/', 'medical/'],
    contentRegex: /\b(PMID|DrugBank|ChEMBL|PubChem|GRADE)\b/,
  },
  'political-research': {
    pathSubstrings: ['evidence/policy_documents', 'fec/', 'campaign/'],
    contentRegex: /\b(FEC\s+(filing|report)|Congressional\s+record|990\s+form|H\.R\.\s*\d|S\.\s*\d{2,})\b/,
  },
  'automotive-audit': {
    pathSubstrings: ['recalls/', 'tsb/'],
    contentRegex: /\b(NHTSA|TSB\s+\d|recall\s+number|\d{2}V-\d{3}|dealer\s+invoice|VIN[:\s])\b/i,
  },
};

const LABELS = ['VERIFIED', 'SUPPORTED', 'INFERRED', 'UNVERIFIED', 'GAP', 'DIRECT'];

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

function detectCodex() {
  try {
    execSync('command -v codex', { stdio: 'ignore' });
    return true;
  } catch (_) {
    return false;
  }
}

function scanResearch(repoPath) {
  if (!fs.existsSync(repoPath)) {
    throw new Error(`Repo path does not exist: ${repoPath}`);
  }
  const stat = fs.statSync(repoPath);
  if (!stat.isDirectory()) {
    throw new Error(`Repo path is not a directory: ${repoPath}`);
  }
  const repoRoot = path.resolve(repoPath);

  const domain = {
    'medical-legal': 0,
    'political-research': 0,
    'automotive-audit': 0,
    'general-research': 1, // baseline — wins ties
  };
  const labelCounts = {};
  for (const l of LABELS) labelCounts[l] = 0;

  const tooling = {
    sdlc_wizard: false,
    codex: detectCodex(),
    regression_test: fs.existsSync(path.join(repoRoot, 'scripts/regression_test.sh')),
    slop_scan: fs.existsSync(path.join(repoRoot, 'scripts/slop_scan.sh')),
    agents_md: fs.existsSync(path.join(repoRoot, 'AGENTS.md')),
    claude_md: fs.existsSync(path.join(repoRoot, 'CLAUDE.md')),
    rdlc_md: fs.existsSync(path.join(repoRoot, 'RDLC.md')),
  };
  if (
    fs.existsSync(path.join(repoRoot, 'SDLC.md')) ||
    fs.existsSync(path.join(repoRoot, '.claude/hooks/sdlc-prompt-check.sh'))
  ) {
    tooling.sdlc_wizard = true;
  }

  const structure = {
    has_evidence: fs.existsSync(path.join(repoRoot, 'evidence')),
    has_research: fs.existsSync(path.join(repoRoot, 'research')),
    has_sources: fs.existsSync(path.join(repoRoot, 'sources')),
    has_output: fs.existsSync(path.join(repoRoot, 'output')),
    has_reviews: fs.existsSync(path.join(repoRoot, '.reviews')),
    has_scripts: fs.existsSync(path.join(repoRoot, 'scripts')),
  };

  const visited = new Set([fs.realpathSync(repoRoot)]);

  walk(
    repoRoot,
    (filePath, name) => {
      if (!name.endsWith('.md')) return;
      const rel = path.relative(repoRoot, filePath);
      const relPosix = rel.split(path.sep).join('/');

      // Path-based domain signals
      for (const [domainName, def] of Object.entries(DOMAIN_PATTERNS)) {
        for (const sub of def.pathSubstrings) {
          if (relPosix.includes(sub)) {
            domain[domainName]++;
          }
        }
      }

      // Content-based scans (read the file once, apply all greps)
      let content;
      try {
        content = fs.readFileSync(filePath, 'utf8');
      } catch (_) {
        return;
      }

      for (const [domainName, def] of Object.entries(DOMAIN_PATTERNS)) {
        if (def.contentRegex && def.contentRegex.test(content)) {
          domain[domainName]++;
        }
      }

      // Confidence-label counting: word-boundary match per label
      for (const label of LABELS) {
        const re = new RegExp(`\\b${label}\\b`, 'g');
        const m = content.match(re);
        if (m) labelCounts[label] += m.length;
      }
    },
    null,
    visited
  );

  // Recommendation: highest-scoring domain. Baseline of 1 on general-research
  // ensures it wins ties cleanly without an extra tiebreak rule.
  let recommended = 'general-research';
  let best = domain['general-research'];
  for (const [name, score] of Object.entries(domain)) {
    if (score > best) {
      best = score;
      recommended = name;
    }
  }

  const totalLabels = LABELS.reduce((a, l) => a + labelCounts[l], 0);
  labelCounts.convention_in_use = totalLabels >= 3;

  return {
    domain,
    recommended_domain: recommended,
    confidence_labels: labelCounts,
    tooling,
    structure,
  };
}

module.exports = { scanResearch };

if (require.main === module) {
  const target = process.argv[2] || '.';
  try {
    const result = scanResearch(target);
    process.stdout.write(JSON.stringify(result, null, 2) + '\n');
  } catch (err) {
    process.stderr.write(`error: ${err.message}\n`);
    process.exit(2);
  }
}
