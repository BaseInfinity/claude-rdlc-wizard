#!/usr/bin/env bash
# Tests for rdlc-wizard CLI `complexity` subcommand.
# Run: bash tests/test-cli-complexity.sh

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

echo "=== CLI COMPLEXITY TESTS ==="
echo ""

assert "cli/bin/rdlc-wizard.js exists" '[ -f "$CLI" ]'
assert "cli/lib/repo-complexity.js exists" '[ -f "$ROOT/cli/lib/repo-complexity.js" ]'

if [ ! -f "$CLI" ]; then echo "SKIP: CLI not built"; exit 1; fi
if ! command -v node >/dev/null 2>&1; then echo "SKIP: node not installed"; exit 0; fi

# --- Scenario 1: empty dir → simple tier ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-complexity-empty-XXXXXX")
out_empty=$(node "$CLI" complexity "$TMPDIR_TEST" 2>&1)
assert "empty dir: output is valid JSON" 'echo "$out_empty" | jq -e . >/dev/null'
assert "empty dir: tier == simple" 'echo "$out_empty" | jq -e ".tier == \"simple\"" >/dev/null'
assert "empty dir: score == 0" 'echo "$out_empty" | jq -e ".score == 0" >/dev/null'
rm -rf "$TMPDIR_TEST"

# --- Scenario 2: light research repo → simple tier ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-complexity-light-XXXXXX")
mkdir -p "$TMPDIR_TEST/output" "$TMPDIR_TEST/research" "$TMPDIR_TEST/sources"
echo "draft" > "$TMPDIR_TEST/output/deliverable_v1.md"
echo "notes" > "$TMPDIR_TEST/research/notes.md"
echo "src" > "$TMPDIR_TEST/sources/source_a.md"
out_light=$(node "$CLI" complexity "$TMPDIR_TEST" 2>&1)
assert "light repo: tier == simple" 'echo "$out_light" | jq -e ".tier == \"simple\"" >/dev/null'
rm -rf "$TMPDIR_TEST"

# --- Scenario 3: heavy multi-deliverable / multi-source → complex tier ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-complexity-heavy-XXXXXX")
mkdir -p "$TMPDIR_TEST/output" "$TMPDIR_TEST/research" "$TMPDIR_TEST/sources" "$TMPDIR_TEST/evidence/interviews" "$TMPDIR_TEST/evidence/documents" "$TMPDIR_TEST/evidence/photos" "$TMPDIR_TEST/evidence/maps" "$TMPDIR_TEST/evidence/audio"
for i in $(seq 1 6); do echo "d$i" > "$TMPDIR_TEST/output/deliverable_$i.md"; done
for i in $(seq 1 25); do echo "r$i" > "$TMPDIR_TEST/research/note_$i.md"; done
for i in $(seq 1 25); do echo "s$i" > "$TMPDIR_TEST/sources/source_$i.md"; done
out_heavy=$(node "$CLI" complexity "$TMPDIR_TEST" 2>&1)
assert "heavy repo: tier == complex" 'echo "$out_heavy" | jq -e ".tier == \"complex\"" >/dev/null'
assert "heavy repo: score >= 6" 'echo "$out_heavy" | jq -e ".score >= 6" >/dev/null'
rm -rf "$TMPDIR_TEST"

# --- Scenario 4: stakes file overrides to complex ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-complexity-stakes-XXXXXX")
echo "secret_token=abc" > "$TMPDIR_TEST/.env"
out_stakes=$(node "$CLI" complexity "$TMPDIR_TEST" 2>&1)
assert "stakes file: tier overridden to complex" 'echo "$out_stakes" | jq -e ".tier == \"complex\"" >/dev/null'
assert "stakes file: signals include override" 'echo "$out_stakes" | jq -e ".signals | map(select(. == \"override:stakes-forces-complex\")) | length == 1" >/dev/null'
rm -rf "$TMPDIR_TEST"

# --- Scenario 5b: root-level deliverables (no output/ dir) — v0.3.2 ---
# Catches v0.3.1 dogfood finding: tucson stores car_report.{md,html,pdf} at root.
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-complexity-rootdeliv-XXXXXX")
mkdir -p "$TMPDIR_TEST/research"
echo "research notes" > "$TMPDIR_TEST/research/notes.md"
# Render-paired root-level deliverables (md + html siblings)
for stem in car_report dads_cheatsheet dealer_audit; do
  echo "deliverable" > "$TMPDIR_TEST/$stem.md"
  echo "<html></html>" > "$TMPDIR_TEST/$stem.html"
done
# Excluded — meta docs at root with html siblings should NOT count
echo "readme" > "$TMPDIR_TEST/README.md"
echo "<html>readme</html>" > "$TMPDIR_TEST/README.html"
out_root=$(node "$CLI" complexity "$TMPDIR_TEST" 2>&1)
assert "root-level paired deliverables: deliverables count >= 3" 'echo "$out_root" | jq -e ".signals[] | select(test(\"deliverables:[3-9]\"))" >/dev/null'
assert "root-level: README.md does NOT count as deliverable" 'echo "$out_root" | jq -e ".signals[] | select(test(\"deliverables:[0-9]+\"))" | jq -e ". | test(\"deliverables:3 \")" >/dev/null'
rm -rf "$TMPDIR_TEST"

# --- Scenario 6: nonexistent path → exit 2 ---
node "$CLI" complexity /this/path/should/not/exist >/dev/null 2>&1; exit_bad=$?
assert "nonexistent path: exit 2" '[ "$exit_bad" -eq 2 ]'

TMPDIR_TEST=""

echo ""
echo "=== SUMMARY ==="
echo "PASS: $PASS  /  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
