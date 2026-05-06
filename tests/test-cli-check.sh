#!/usr/bin/env bash
# Tests for rdlc-wizard CLI `check` subcommand.
# Run: bash tests/test-cli-check.sh
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

echo "=== CLI CHECK TESTS ==="
echo ""

assert "cli/bin/rdlc-wizard.js exists" '[ -f "$CLI" ]'

if [ ! -f "$CLI" ]; then
  echo "SKIP: CLI not built"
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "SKIP: node not installed"
  exit 0
fi

# --- Scenario 1: empty dir → MISSING for everything → drift, exit 1 ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-check-empty-XXXXXX")
out_empty=$(cd "$TMPDIR_TEST" && node "$CLI" check 2>&1)
exit_empty=$?
# In a subshell, $? from the inside isn't captured; rerun for exit code
(cd "$TMPDIR_TEST" && node "$CLI" check >/dev/null 2>&1); exit_empty=$?
assert "empty dir: check exits non-zero" '[ "$exit_empty" -ne 0 ]'
assert "empty dir: reports MISSING for RDLC.md" 'echo "$out_empty" | grep -q "MISSING.*RDLC.md"'
rm -rf "$TMPDIR_TEST"

# --- Scenario 2: clean install → all MATCH, exit 0 ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-check-clean-XXXXXX")
(cd "$TMPDIR_TEST" && node "$CLI" init >/dev/null 2>&1)
out_clean=$(cd "$TMPDIR_TEST" && node "$CLI" check 2>&1)
(cd "$TMPDIR_TEST" && node "$CLI" check >/dev/null 2>&1); exit_clean=$?
assert "clean install: check exits 0" '[ "$exit_clean" -eq 0 ]'
assert "clean install: reports MATCH for RDLC.md" 'echo "$out_clean" | grep -q "MATCH.*RDLC.md"'
assert "clean install: no MISSING entries" '! echo "$out_clean" | grep -q "MISSING"'
rm -rf "$TMPDIR_TEST"

# --- Scenario 3: customized RDLC.md → CUSTOMIZED status, no drift ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-check-customized-XXXXXX")
(cd "$TMPDIR_TEST" && node "$CLI" init >/dev/null 2>&1)
echo "<!-- user added a comment -->" >> "$TMPDIR_TEST/RDLC.md"
out_custom=$(cd "$TMPDIR_TEST" && node "$CLI" check 2>&1)
(cd "$TMPDIR_TEST" && node "$CLI" check >/dev/null 2>&1); exit_custom=$?
assert "customized RDLC.md: check exits 0 (CUSTOMIZED is not drift)" '[ "$exit_custom" -eq 0 ]'
assert "customized RDLC.md: reports CUSTOMIZED" 'echo "$out_custom" | grep -q "CUSTOMIZED.*RDLC.md"'
rm -rf "$TMPDIR_TEST"

# --- Scenario 4: missing executable bit on a hook → DRIFT, exit 1 ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-check-noexec-XXXXXX")
(cd "$TMPDIR_TEST" && node "$CLI" init >/dev/null 2>&1)
chmod -x "$TMPDIR_TEST/.claude/hooks/rdlc-prompt-check.sh"
out_noexec=$(cd "$TMPDIR_TEST" && node "$CLI" check 2>&1)
(cd "$TMPDIR_TEST" && node "$CLI" check >/dev/null 2>&1); exit_noexec=$?
assert "missing exec bit: check exits non-zero" '[ "$exit_noexec" -ne 0 ]'
assert "missing exec bit: reports DRIFT" 'echo "$out_noexec" | grep -q "DRIFT"'
rm -rf "$TMPDIR_TEST"

# --- Scenario 5: --json flag emits valid JSON ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-check-json-XXXXXX")
(cd "$TMPDIR_TEST" && node "$CLI" init >/dev/null 2>&1)
json_out=$(cd "$TMPDIR_TEST" && node "$CLI" check --json 2>&1)
assert "--json output parses as valid JSON" 'echo "$json_out" | jq -e . >/dev/null'
assert "--json output has files array" 'echo "$json_out" | jq -e ".files | type == \"array\"" >/dev/null'
rm -rf "$TMPDIR_TEST"

TMPDIR_TEST=""

echo ""
echo "=== SUMMARY ==="
echo "PASS: $PASS  /  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
