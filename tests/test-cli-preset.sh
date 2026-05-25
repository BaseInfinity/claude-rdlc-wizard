#!/usr/bin/env bash
# Tests for rdlc-wizard preset auto-detection and install (v0.6+).
# Run: bash tests/test-cli-preset.sh
#
# Ships goal: prove medical-legal preset auto-detects from research signals
# and gets installed in place of the generic RDLC.md.

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

echo "=== CLI PRESET TESTS ==="
echo ""

if [ ! -f "$CLI" ]; then echo "SKIP: CLI not built"; exit 1; fi
if ! command -v node >/dev/null 2>&1; then echo "SKIP: node not installed"; exit 0; fi

# --- Preset file existence (the canonical lives in the repo) ---
assert "presets/ directory exists" '[ -d "$ROOT/presets" ]'
assert "presets/medical-legal/RDLC.md exists" '[ -f "$ROOT/presets/medical-legal/RDLC.md" ]'
assert "medical preset RDLC.md mentions GRADE" 'grep -q "GRADE" "$ROOT/presets/medical-legal/RDLC.md"'
assert "medical preset RDLC.md mentions DrugBank" 'grep -q "DrugBank" "$ROOT/presets/medical-legal/RDLC.md"'
assert "medical preset RDLC.md mentions ChEMBL" 'grep -q "ChEMBL" "$ROOT/presets/medical-legal/RDLC.md"'
assert "medical preset RDLC.md mentions PubChem" 'grep -q "PubChem" "$ROOT/presets/medical-legal/RDLC.md"'
assert "medical preset RDLC.md mentions openFDA" 'grep -q "openFDA" "$ROOT/presets/medical-legal/RDLC.md"'
assert "medical preset RDLC.md declares Domain: medical-legal" 'grep -q "Domain: medical-legal" "$ROOT/presets/medical-legal/RDLC.md"'
# GRADE-aligned uncertainty labels (from anticheat)
assert "medical preset RDLC.md has GRADE quality scale" 'grep -qE "Very Low.*Low.*Moderate.*High|GRADE: (Very Low|Low|Moderate|High)" "$ROOT/presets/medical-legal/RDLC.md"'

# --- Help surface ---
help_out=$(node "$CLI" --help 2>&1 || true)
assert "--help mentions --preset flag" 'echo "$help_out" | grep -q -- "--preset"'

# --- Scenario A: explicit --preset medical-legal ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-preset-explicit-XXXXXX")
(cd "$TMPDIR_TEST" && node "$CLI" init --preset medical-legal >/dev/null 2>&1)
assert "explicit preset: RDLC.md installed" '[ -f "$TMPDIR_TEST/RDLC.md" ]'
assert "explicit preset: installed RDLC.md is medical-legal variant" 'grep -q "Domain: medical-legal" "$TMPDIR_TEST/RDLC.md"'
assert "explicit preset: installed RDLC.md has GRADE" 'grep -q "GRADE" "$TMPDIR_TEST/RDLC.md"'
rm -rf "$TMPDIR_TEST"

# --- Scenario B: auto-detect from medical signals ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-preset-auto-med-XXXXXX")
mkdir -p "$TMPDIR_TEST/evidence/team_profiles" "$TMPDIR_TEST/research"
echo "Reference: PMID 12345678" > "$TMPDIR_TEST/research/study.md"
echo "DrugBank: DB00945, ChEMBL: CHEMBL25, PubChem CID 1234" > "$TMPDIR_TEST/research/drugs.md"
echo "GRADE: high quality evidence" > "$TMPDIR_TEST/evidence/team_profiles/expert.md"
(cd "$TMPDIR_TEST" && node "$CLI" init >/dev/null 2>&1)
assert "auto medical: RDLC.md installed" '[ -f "$TMPDIR_TEST/RDLC.md" ]'
assert "auto medical: installed RDLC.md is medical-legal variant (not generic)" 'grep -q "Domain: medical-legal" "$TMPDIR_TEST/RDLC.md"'
rm -rf "$TMPDIR_TEST"

# --- Scenario C: empty/no-signal dir → generic RDLC.md (NOT a preset) ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-preset-generic-XXXXXX")
(cd "$TMPDIR_TEST" && node "$CLI" init >/dev/null 2>&1)
assert "empty dir: RDLC.md installed" '[ -f "$TMPDIR_TEST/RDLC.md" ]'
assert "empty dir: NOT the medical preset (no GRADE-quality scale)" '! grep -qE "GRADE: (Very Low|Low|Moderate|High)" "$TMPDIR_TEST/RDLC.md"'
rm -rf "$TMPDIR_TEST"

# --- Scenario D: --preset overrides auto-detect ---
# Set up medical signals but explicitly pass --preset general-research → should NOT
# install medical preset.
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-preset-override-XXXXXX")
mkdir -p "$TMPDIR_TEST/research"
echo "PMID 12345, DrugBank DB001, ChEMBL CHEMBL1" > "$TMPDIR_TEST/research/study.md"
(cd "$TMPDIR_TEST" && node "$CLI" init --preset general-research >/dev/null 2>&1)
assert "override: RDLC.md installed" '[ -f "$TMPDIR_TEST/RDLC.md" ]'
assert "override: NOT medical-legal despite medical signals" '! grep -q "Domain: medical-legal" "$TMPDIR_TEST/RDLC.md"'
rm -rf "$TMPDIR_TEST"

# --- Scenario E: unknown preset name → non-zero exit, no install ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-preset-unknown-XXXXXX")
(cd "$TMPDIR_TEST" && node "$CLI" init --preset bogus-domain >/dev/null 2>&1); exit_unknown=$?
assert "unknown preset: non-zero exit" '[ "$exit_unknown" -ne 0 ]'
assert "unknown preset: no RDLC.md written" '[ ! -f "$TMPDIR_TEST/RDLC.md" ]'
rm -rf "$TMPDIR_TEST"

TMPDIR_TEST=""

echo ""
echo "=== SUMMARY ==="
echo "PASS: $PASS  /  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
