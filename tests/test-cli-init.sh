#!/usr/bin/env bash
# Tests for rdlc-wizard CLI `init` subcommand.
# Run: bash tests/test-cli-init.sh
# Exit 0 = pass, 1 = fail

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT/cli/bin/rdlc-wizard.js"

FAIL=0
PASS=0
TMPDIR_TEST=""

red()   { printf "\033[31mFAIL: %s\033[0m\n" "$1"; }
green() { printf "\033[32mPASS: %s\033[0m\n" "$1"; }

assert() {
  local label="$1"
  if eval "$2"; then
    green "$label"
    PASS=$((PASS + 1))
  else
    red "$label"
    FAIL=$((FAIL + 1))
  fi
}

cleanup() {
  [ -n "$TMPDIR_TEST" ] && [ -d "$TMPDIR_TEST" ] && rm -rf "$TMPDIR_TEST"
}
trap cleanup EXIT

echo "=== CLI INIT TESTS ==="
echo ""

# Pre-flight: CLI binary must exist (TDD red phase fails here until implemented)
assert "cli/bin/rdlc-wizard.js exists" '[ -f "$CLI" ]'

if [ ! -f "$CLI" ]; then
  echo ""
  echo "SKIP REMAINING: rdlc-wizard.js not yet implemented (this is expected during TDD red phase)."
  echo ""
  echo "=== SUMMARY ==="
  echo "PASS: $PASS  /  FAIL: $FAIL"
  exit 1
fi

# Pre-flight: node must be available
if ! command -v node >/dev/null 2>&1; then
  echo "SKIP: node not installed"
  exit 0
fi

# Setup: clean temp dir as install target
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-init-test-XXXXXX")

# Run init against the temp dir
(cd "$TMPDIR_TEST" && node "$CLI" init >/dev/null 2>&1)

# --- File-creation assertions ---
assert "RDLC.md created at repo root" '[ -f "$TMPDIR_TEST/RDLC.md" ]'
assert ".claude/settings.json created" '[ -f "$TMPDIR_TEST/.claude/settings.json" ]'
assert "settings.json parses as valid JSON" 'jq -e . "$TMPDIR_TEST/.claude/settings.json" >/dev/null'

# --- Hooks (must be present and executable) ---
for hook in rdlc-prompt-check.sh slop-scan-pretool.sh confidence-required.sh source-required.sh audience-firewall.sh rdlc-instructions-check.sh _find-rdlc-root.sh; do
  assert ".claude/hooks/$hook created" '[ -f "$TMPDIR_TEST/.claude/hooks/$hook" ]'
  assert ".claude/hooks/$hook is executable" '[ -x "$TMPDIR_TEST/.claude/hooks/$hook" ]'
done

# --- Skills ---
for skill in rdlc setup update feedback; do
  assert ".claude/skills/$skill/SKILL.md created" '[ -f "$TMPDIR_TEST/.claude/skills/$skill/SKILL.md" ]'
done

# --- Scripts (v0.3.2: init now drops these from templates) ---
assert "scripts/regression_test.sh created" '[ -f "$TMPDIR_TEST/scripts/regression_test.sh" ]'
assert "scripts/regression_test.sh is executable" '[ -x "$TMPDIR_TEST/scripts/regression_test.sh" ]'
assert "scripts/slop_scan.sh created" '[ -f "$TMPDIR_TEST/scripts/slop_scan.sh" ]'
assert "scripts/slop_scan.sh is executable" '[ -x "$TMPDIR_TEST/scripts/slop_scan.sh" ]'
assert "scripts/generate_deliverable.py created" '[ -f "$TMPDIR_TEST/scripts/generate_deliverable.py" ]'

# --- .rdlc/ directory ---
assert ".rdlc/slop-allowlist.txt created" '[ -f "$TMPDIR_TEST/.rdlc/slop-allowlist.txt" ]'
assert ".rdlc/version created" '[ -f "$TMPDIR_TEST/.rdlc/version" ]'
assert ".rdlc/version contains semver" 'grep -qE "^[0-9]+\.[0-9]+\.[0-9]+$" "$TMPDIR_TEST/.rdlc/version"'

# --- gitignore ---
assert ".gitignore created" '[ -f "$TMPDIR_TEST/.gitignore" ]'
assert ".gitignore has .claude/plans/" 'grep -qF ".claude/plans/" "$TMPDIR_TEST/.gitignore"'
assert ".gitignore has .claude/settings.local.json" 'grep -qF ".claude/settings.local.json" "$TMPDIR_TEST/.gitignore"'

# --- Idempotency: second init must SKIP existing files ---
second_run=$(cd "$TMPDIR_TEST" && node "$CLI" init 2>&1)
assert "second init reports SKIP for at least one file" 'echo "$second_run" | grep -q "SKIP"'

# --- CLI surface ---
help_out=$(node "$CLI" --help 2>&1 || true)
assert "--help lists init subcommand" 'echo "$help_out" | grep -q "init"'
assert "--help lists check subcommand" 'echo "$help_out" | grep -q "check"'
assert "--help lists complexity subcommand" 'echo "$help_out" | grep -q "complexity"'

ver_out=$(node "$CLI" --version 2>&1 || true)
assert "--version prints semver" 'echo "$ver_out" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+$"'

# --- Dry-run: must not write files ---
TMPDIR_DRYRUN=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-init-dryrun-XXXXXX")
(cd "$TMPDIR_DRYRUN" && node "$CLI" init --dry-run >/dev/null 2>&1)
assert "--dry-run does not write RDLC.md" '[ ! -f "$TMPDIR_DRYRUN/RDLC.md" ]'
assert "--dry-run does not write .claude/" '[ ! -d "$TMPDIR_DRYRUN/.claude" ]'
rm -rf "$TMPDIR_DRYRUN"

echo ""
echo "=== SUMMARY ==="
echo "PASS: $PASS  /  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
