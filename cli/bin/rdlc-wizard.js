#!/usr/bin/env node
'use strict';

const { version } = require('../../package.json');
const { init, check, listAvailablePresets } = require('../init');
const { detectComplexity } = require('../lib/repo-complexity');
const { scanResearch } = require('../lib/scan-research');

const args = process.argv.slice(2);

// --preset takes a value: `--preset medical-legal` (next arg) or `--preset=medical-legal`.
function readValueFlag(name) {
  const eqIdx = args.findIndex((a) => a.startsWith(`${name}=`));
  if (eqIdx !== -1) return args[eqIdx].slice(name.length + 1);
  const idx = args.indexOf(name);
  if (idx !== -1 && idx + 1 < args.length && !args[idx + 1].startsWith('--')) {
    return args[idx + 1];
  }
  return null;
}

const flags = {
  force: args.includes('--force'),
  dryRun: args.includes('--dry-run'),
  json: args.includes('--json'),
  preset: readValueFlag('--preset'),
};

// Positional args exclude flags AND the value that follows --preset.
const presetValueIdx = flags.preset && !args.some((a) => a.startsWith('--preset='))
  ? args.indexOf('--preset') + 1
  : -1;
const positional = args.filter((a, i) => !a.startsWith('--') && i !== presetValueIdx);
const command = positional[0];

if (args.includes('--version') || args.includes('-v')) {
  console.log(version);
  process.exit(0);
}

if (args.includes('--help') || args.includes('-h') || !command) {
  const presets = listAvailablePresets();
  const presetList = presets.length > 0 ? [...presets, 'general-research'].join(' | ') : 'general-research';
  console.log(`
  claude-rdlc-wizard v${version}

  Usage:
    rdlc-wizard init [options]               Install RDLC wizard into current directory
    rdlc-wizard check [options]              Check installation health and updates
    rdlc-wizard scan [path]                  Print research signals for /setup to consume
    rdlc-wizard complexity [path]            Print research-repo complexity tier

  Options:
    --force            Overwrite existing files (init only)
    --dry-run          Preview changes without writing (init only)
    --preset <name>    Install a domain-specific RDLC.md preset (init only)
                       Available: ${presetList}
                       Default: auto-detect via the scanner (falls back to general)
    --json             Output as JSON (check / scan / complexity)
    --version          Show version
    --help             Show this help
  `.trim());
  process.exit(0);
}

if (command === 'init') {
  try {
    init(process.cwd(), flags);
    process.exit(0);
  } catch (err) {
    console.error(`Error: ${err.message}`);
    process.exit(err.code === 'UNKNOWN_PRESET' ? 2 : 1);
  }
} else if (command === 'check') {
  try {
    const { hasDrift } = check(process.cwd(), { json: flags.json });
    process.exit(hasDrift ? 1 : 0);
  } catch (err) {
    console.error(`Error: ${err.message}`);
    process.exit(1);
  }
} else if (command === 'complexity') {
  try {
    const target = positional[1] || process.cwd();
    const result = detectComplexity(target);
    process.stdout.write(JSON.stringify(result, null, 2) + '\n');
    process.exit(0);
  } catch (err) {
    console.error(`Error: ${err.message}`);
    process.exit(2);
  }
} else if (command === 'scan') {
  try {
    const target = positional[1] || process.cwd();
    const result = scanResearch(target);
    process.stdout.write(JSON.stringify(result, null, 2) + '\n');
    process.exit(0);
  } catch (err) {
    console.error(`Error: ${err.message}`);
    process.exit(2);
  }
} else {
  console.error(`Unknown command: ${command}`);
  console.error('Run "rdlc-wizard --help" for usage.');
  process.exit(1);
}
