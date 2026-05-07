#!/usr/bin/env bash
# Tests for rdlc-wizard CLI `scan` subcommand (v0.3+).
# Run: bash tests/test-cli-scan.sh

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

echo "=== CLI SCAN TESTS ==="
echo ""

assert "cli/bin/rdlc-wizard.js exists" '[ -f "$CLI" ]'

if [ ! -f "$CLI" ]; then echo "SKIP: CLI not built"; exit 1; fi
if ! command -v node >/dev/null 2>&1; then echo "SKIP: node not installed"; exit 0; fi
if ! command -v jq >/dev/null 2>&1; then echo "SKIP: jq not installed"; exit 0; fi

# --- CLI surface ---
help_out=$(node "$CLI" --help 2>&1 || true)
assert "--help lists scan subcommand" 'echo "$help_out" | grep -q "scan"'

# --- Scenario 1: empty dir → low signals everywhere ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-scan-empty-XXXXXX")
out_empty=$(node "$CLI" scan "$TMPDIR_TEST" 2>&1)
assert "empty dir: output is valid JSON" 'echo "$out_empty" | jq -e . >/dev/null'
assert "empty dir: has domain object" 'echo "$out_empty" | jq -e ".domain | type == \"object\"" >/dev/null'
assert "empty dir: has confidence_labels object" 'echo "$out_empty" | jq -e ".confidence_labels | type == \"object\"" >/dev/null'
assert "empty dir: has tooling object" 'echo "$out_empty" | jq -e ".tooling | type == \"object\"" >/dev/null'
assert "empty dir: recommended_domain is general-research" 'echo "$out_empty" | jq -e ".recommended_domain == \"general-research\"" >/dev/null'
assert "empty dir: tooling.sdlc_wizard is false" 'echo "$out_empty" | jq -e ".tooling.sdlc_wizard == false" >/dev/null'
assert "empty dir: confidence_labels.VERIFIED is 0" 'echo "$out_empty" | jq -e ".confidence_labels.VERIFIED == 0" >/dev/null'
rm -rf "$TMPDIR_TEST"

# --- Scenario 2: political-research signals ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-scan-political-XXXXXX")
mkdir -p "$TMPDIR_TEST/evidence/policy_documents" "$TMPDIR_TEST/research"
echo "FEC filing 2024" > "$TMPDIR_TEST/evidence/policy_documents/fec_filing.md"
echo "Congressional record reference: H.R. 123" > "$TMPDIR_TEST/research/congress_note.md"
out_pol=$(node "$CLI" scan "$TMPDIR_TEST" 2>&1)
assert "political: recommended_domain is political-research" 'echo "$out_pol" | jq -e ".recommended_domain == \"political-research\"" >/dev/null'
assert "political: political-research has positive score" 'echo "$out_pol" | jq -e ".domain.\"political-research\" > 0" >/dev/null'
rm -rf "$TMPDIR_TEST"

# --- Scenario 3: medical-legal signals ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-scan-medical-XXXXXX")
mkdir -p "$TMPDIR_TEST/evidence/team_profiles" "$TMPDIR_TEST/research"
echo "Reference: PMID 12345678" > "$TMPDIR_TEST/research/study.md"
echo "DrugBank: DB00945, ChEMBL: CHEMBL25" > "$TMPDIR_TEST/research/drugs.md"
echo "GRADE: high quality evidence" > "$TMPDIR_TEST/evidence/team_profiles/expert.md"
out_med=$(node "$CLI" scan "$TMPDIR_TEST" 2>&1)
assert "medical: recommended_domain is medical-legal" 'echo "$out_med" | jq -e ".recommended_domain == \"medical-legal\"" >/dev/null'
rm -rf "$TMPDIR_TEST"

# --- Scenario 4: automotive-audit signals ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-scan-auto-XXXXXX")
mkdir -p "$TMPDIR_TEST/evidence" "$TMPDIR_TEST/research"
echo "NHTSA TSB 2024-001 — recall number 24V-123" > "$TMPDIR_TEST/research/recall.md"
echo "Dealer invoice from servicing department" > "$TMPDIR_TEST/evidence/invoice.md"
out_auto=$(node "$CLI" scan "$TMPDIR_TEST" 2>&1)
assert "automotive: recommended_domain is automotive-audit" 'echo "$out_auto" | jq -e ".recommended_domain == \"automotive-audit\"" >/dev/null'
rm -rf "$TMPDIR_TEST"

# --- Scenario 5: existing confidence labels ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-scan-labels-XXXXXX")
mkdir -p "$TMPDIR_TEST/research"
cat > "$TMPDIR_TEST/research/notes.md" <<'EOF'
# Notes

VERIFIED: First claim with two sources.
SUPPORTED: Second claim with one source.
VERIFIED: Third claim, also verified.
INFERRED: Fourth claim based on indirect evidence.
UNVERIFIED: Fifth claim, no source yet.
EOF
out_labels=$(node "$CLI" scan "$TMPDIR_TEST" 2>&1)
assert "labels: VERIFIED count is 2" 'echo "$out_labels" | jq -e ".confidence_labels.VERIFIED == 2" >/dev/null'
assert "labels: SUPPORTED count is 1" 'echo "$out_labels" | jq -e ".confidence_labels.SUPPORTED == 1" >/dev/null'
assert "labels: INFERRED count is 1" 'echo "$out_labels" | jq -e ".confidence_labels.INFERRED == 1" >/dev/null'
assert "labels: UNVERIFIED count is 1" 'echo "$out_labels" | jq -e ".confidence_labels.UNVERIFIED == 1" >/dev/null'
assert "labels: convention_in_use is true" 'echo "$out_labels" | jq -e ".confidence_labels.convention_in_use == true" >/dev/null'
rm -rf "$TMPDIR_TEST"

# --- Scenario 6: sdlc-wizard pairing ---
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-scan-sdlc-XXXXXX")
echo "# SDLC Configuration" > "$TMPDIR_TEST/SDLC.md"
mkdir -p "$TMPDIR_TEST/.claude/hooks"
touch "$TMPDIR_TEST/.claude/hooks/sdlc-prompt-check.sh"
out_sdlc=$(node "$CLI" scan "$TMPDIR_TEST" 2>&1)
assert "sdlc-paired: tooling.sdlc_wizard is true" 'echo "$out_sdlc" | jq -e ".tooling.sdlc_wizard == true" >/dev/null'
rm -rf "$TMPDIR_TEST"

# --- Scenario 7: files outside research dirs do NOT influence content scoring ---
# Catches v0.3.0 dogfood finding: wizard's own RDLC.md was bumping medical score.
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-scan-scope-XXXXXX")
echo "Sample: PMID 12345, DrugBank DB001, FEC filing, NHTSA recall." > "$TMPDIR_TEST/RDLC.md"
echo "VERIFIED claim. SUPPORTED claim. UNVERIFIED claim." > "$TMPDIR_TEST/notes.md"
mkdir -p "$TMPDIR_TEST/scripts"
echo "VERIFIED check_present helper" > "$TMPDIR_TEST/scripts/regression_test.sh"
out_scope=$(node "$CLI" scan "$TMPDIR_TEST" 2>&1)
assert "scope: root .md does not score medical-legal" 'echo "$out_scope" | jq -e ".domain.\"medical-legal\" == 0" >/dev/null'
assert "scope: root .md does not score political-research" 'echo "$out_scope" | jq -e ".domain.\"political-research\" == 0" >/dev/null'
assert "scope: root .md does not score automotive-audit" 'echo "$out_scope" | jq -e ".domain.\"automotive-audit\" == 0" >/dev/null'
assert "scope: root .md does not count VERIFIED" 'echo "$out_scope" | jq -e ".confidence_labels.VERIFIED == 0" >/dev/null'
assert "scope: convention_in_use false (no research/evidence files)" 'echo "$out_scope" | jq -e ".confidence_labels.convention_in_use == false" >/dev/null'
# now move content into research/ — scoring should turn on
mkdir -p "$TMPDIR_TEST/research"
mv "$TMPDIR_TEST/notes.md" "$TMPDIR_TEST/research/notes.md"
out_scope2=$(node "$CLI" scan "$TMPDIR_TEST" 2>&1)
assert "scope: research/ .md does count VERIFIED" 'echo "$out_scope2" | jq -e ".confidence_labels.VERIFIED == 1" >/dev/null'
rm -rf "$TMPDIR_TEST"

# --- Scenario 8: nonexistent path → exit non-zero ---
node "$CLI" scan /this/path/should/not/exist >/dev/null 2>&1; exit_bad=$?
assert "nonexistent path: non-zero exit" '[ "$exit_bad" -ne 0 ]'

TMPDIR_TEST=""

echo ""
echo "=== SUMMARY ==="
echo "PASS: $PASS  /  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
