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

# --- Preset file existence (the canonicals live in the repo) ---
assert "presets/ directory exists" '[ -d "$ROOT/presets" ]'

# medical-legal preset (from anticheat)
assert "presets/medical-legal/RDLC.md exists" '[ -f "$ROOT/presets/medical-legal/RDLC.md" ]'
assert "medical preset RDLC.md mentions GRADE" 'grep -q "GRADE" "$ROOT/presets/medical-legal/RDLC.md"'
assert "medical preset RDLC.md mentions DrugBank" 'grep -q "DrugBank" "$ROOT/presets/medical-legal/RDLC.md"'
assert "medical preset RDLC.md mentions ChEMBL" 'grep -q "ChEMBL" "$ROOT/presets/medical-legal/RDLC.md"'
assert "medical preset RDLC.md mentions PubChem" 'grep -q "PubChem" "$ROOT/presets/medical-legal/RDLC.md"'
assert "medical preset RDLC.md mentions openFDA" 'grep -q "openFDA" "$ROOT/presets/medical-legal/RDLC.md"'
assert "medical preset RDLC.md declares Domain: medical-legal" 'grep -q "Domain: medical-legal" "$ROOT/presets/medical-legal/RDLC.md"'
assert "medical preset RDLC.md has GRADE quality scale" 'grep -qE "Very Low.*Low.*Moderate.*High|GRADE: (Very Low|Low|Moderate|High)" "$ROOT/presets/medical-legal/RDLC.md"'

# political-research preset (from states-project-research)
assert "presets/political-research/RDLC.md exists" '[ -f "$ROOT/presets/political-research/RDLC.md" ]'
assert "political preset declares Domain: political-research" 'grep -q "Domain: political-research" "$ROOT/presets/political-research/RDLC.md"'
assert "political preset mentions FEC" 'grep -q "FEC" "$ROOT/presets/political-research/RDLC.md"'
assert "political preset mentions Congressional records" 'grep -qE "Congress(ional)? (records|\\.gov)" "$ROOT/presets/political-research/RDLC.md"'
assert "political preset mentions 990 forms" 'grep -qE "990 form|IRS Form 990|990s" "$ROOT/presets/political-research/RDLC.md"'
assert "political preset mentions OpenSecrets" 'grep -q "OpenSecrets" "$ROOT/presets/political-research/RDLC.md"'
assert "political preset has VERIFIED/SUPPORTED/INFERRED/UNVERIFIED labels" 'grep -q "VERIFIED" "$ROOT/presets/political-research/RDLC.md" && grep -q "SUPPORTED" "$ROOT/presets/political-research/RDLC.md" && grep -q "INFERRED" "$ROOT/presets/political-research/RDLC.md" && grep -q "UNVERIFIED" "$ROOT/presets/political-research/RDLC.md"'
assert "political preset mentions mock-interview leak prevention" 'grep -qE "mock.interview|mock_" "$ROOT/presets/political-research/RDLC.md"'

# automotive-audit preset (from tucson-investigation)
assert "presets/automotive-audit/RDLC.md exists" '[ -f "$ROOT/presets/automotive-audit/RDLC.md" ]'
assert "automotive preset declares Domain: automotive-audit" 'grep -q "Domain: automotive-audit" "$ROOT/presets/automotive-audit/RDLC.md"'
assert "automotive preset mentions NHTSA" 'grep -q "NHTSA" "$ROOT/presets/automotive-audit/RDLC.md"'
assert "automotive preset mentions TSB" 'grep -q "TSB" "$ROOT/presets/automotive-audit/RDLC.md"'
assert "automotive preset mentions VIN" 'grep -q "VIN" "$ROOT/presets/automotive-audit/RDLC.md"'
assert "automotive preset has DIRECT label" 'grep -q "DIRECT" "$ROOT/presets/automotive-audit/RDLC.md"'
assert "automotive preset has GAP label as first-class" 'grep -qE "GAP.*structurally unknowable|GAP.*record does not exist" "$ROOT/presets/automotive-audit/RDLC.md"'
assert "automotive preset mentions methodology-leak gate" 'grep -qE "methodology.leak|methodology never|methodology in the wrong" "$ROOT/presets/automotive-audit/RDLC.md"'
assert "automotive preset mentions persona tests" 'grep -qE "persona|Playwright" "$ROOT/presets/automotive-audit/RDLC.md"'

# --- Help surface ---
help_out=$(node "$CLI" --help 2>&1 || true)
assert "--help mentions --preset flag" 'echo "$help_out" | grep -q -- "--preset"'
assert "--help lists all 3 presets" 'echo "$help_out" | grep -q "medical-legal" && echo "$help_out" | grep -q "political-research" && echo "$help_out" | grep -q "automotive-audit"'

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

# --- Scenario B2: auto-detect from political signals ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-preset-auto-pol-XXXXXX")
mkdir -p "$TMPDIR_TEST/evidence/policy_documents" "$TMPDIR_TEST/research"
echo "FEC filing reference 2024-Q3" > "$TMPDIR_TEST/evidence/policy_documents/fec.md"
echo "Congressional record: H.R. 1234, S. 567" > "$TMPDIR_TEST/research/congress.md"
(cd "$TMPDIR_TEST" && node "$CLI" init >/dev/null 2>&1)
assert "auto political: RDLC.md installed" '[ -f "$TMPDIR_TEST/RDLC.md" ]'
assert "auto political: installed RDLC.md is political-research variant" 'grep -q "Domain: political-research" "$TMPDIR_TEST/RDLC.md"'
rm -rf "$TMPDIR_TEST"

# --- Scenario B3: auto-detect from automotive signals ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-preset-auto-auto-XXXXXX")
mkdir -p "$TMPDIR_TEST/evidence" "$TMPDIR_TEST/research"
echo "NHTSA TSB 24-01-049 — recall 24V-123" > "$TMPDIR_TEST/research/recall.md"
echo "Dealer invoice for service work — VIN ABC123" > "$TMPDIR_TEST/evidence/invoice.md"
(cd "$TMPDIR_TEST" && node "$CLI" init >/dev/null 2>&1)
assert "auto automotive: RDLC.md installed" '[ -f "$TMPDIR_TEST/RDLC.md" ]'
assert "auto automotive: installed RDLC.md is automotive-audit variant" 'grep -q "Domain: automotive-audit" "$TMPDIR_TEST/RDLC.md"'
rm -rf "$TMPDIR_TEST"

# --- Scenario B4: explicit --preset for all 3 presets ---
for p in medical-legal political-research automotive-audit; do
  TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-preset-explicit-${p}-XXXXXX")
  (cd "$TMPDIR_TEST" && node "$CLI" init --preset "$p" >/dev/null 2>&1)
  assert "explicit preset $p: installed correct variant" 'grep -q "Domain: '"$p"'" "$TMPDIR_TEST/RDLC.md"'
  rm -rf "$TMPDIR_TEST"
done

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
