#!/usr/bin/env bash
# Enforcement tests for claude-rdlc-wizard PreToolUse gate hooks.
# Traces actual exit codes and stderr routing on every "should block" branch —
# added after the Fable self-enforcement audit (issue #9; mirrors sdlc-wizard #436).
#
# Harness contract under test:
#   - strict mode (RDLC_HOOKS_STRICT=1) blocks: exit 2 AND the reason on stderr
#   - soft mode warns visibly: exit 1 (non-blocking) AND the warning on stderr
#   - clean content: exit 0, silent
#
# Run: bash tests/test-hooks-enforcement.sh
# Requires: jq

set -uo pipefail

# Hook silence assertions must not inherit host-specific locale startup warnings.
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS="$ROOT/hooks"

FAIL=0
PASS=0

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

if ! command -v jq >/dev/null 2>&1; then
  echo "SETUP FAILED: jq is required for enforcement tests" >&2
  exit 1
fi

echo "=== HOOK ENFORCEMENT TESTS ==="
echo ""

# --- fixtures ---------------------------------------------------------------

WORK=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-enforce-XXXXXX") || { echo "SETUP FAILED: mktemp" >&2; exit 1; }
trap 'rm -rf "$WORK"' EXIT

# Full RDLC project fixture
PROJ="$WORK/proj"
mkdir -p "$PROJ/.claude/hooks" "$PROJ/.rdlc" "$PROJ/research" "$PROJ/output"
printf '<!-- RDLC Wizard Version: test -->\n# RDLC Configuration\n' > "$PROJ/RDLC.md"
cp "$HOOKS/rdlc-prompt-check.sh" "$PROJ/.claude/hooks/"

# Partial fixture: hooks installed, RDLC.md deleted (fail-open probe)
PARTIAL="$WORK/partial"
mkdir -p "$PARTIAL/.claude/hooks"
cp "$HOOKS/rdlc-prompt-check.sh" "$PARTIAL/.claude/hooks/"

# run_hook <hook-file> <payload> <strict> <dir> — sets EC / OUT / ERR
run_hook() {
  local hook="$1" payload="$2" strict="$3" dir="$4"
  local outf="$WORK/stdout.$$" errf="$WORK/stderr.$$"
  set +e
  ( cd "$dir" && printf '%s' "$payload" \
      | env CLAUDE_PROJECT_DIR="$dir" RDLC_HOOKS_STRICT="$strict" bash "$HOOKS/$hook" ) \
      >"$outf" 2>"$errf"
  EC=$?
  set +e
  OUT=$(cat "$outf"); ERR=$(cat "$errf")
  rm -f "$outf" "$errf"
}

payload_write() { # <file_path> <content>
  jq -n --arg fp "$1" --arg c "$2" '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}'
}

SLOP_CONTENT='Let us deep dive into the cutting-edge paradigm shift.'
CLEAN_CONTENT='The committee approved the annual budget during the March session.
The final vote passed with seven members in favor of adoption.'
LABELED_CONTENT='VERIFIED: The committee approved the annual budget during the March session.
The final vote passed with seven members in favor of adoption. [Source: council minutes]'
SINGAPORE_CONTENT='SINGAPORE trade officials approved the annual budget during the March session.
The final vote passed with seven DIRECTORS of the GAPINDUSTRY board in favor.'
THREE_PARA_NO_SOURCE='The committee approved the annual budget during the March session.
The final vote passed with seven members in favor of adoption.
The dissenting members filed a formal objection with the county clerk.'

# --- slop-scan-pretool.sh ----------------------------------------------------

P=$(payload_write "$PROJ/research/notes.md" "$SLOP_CONTENT")

run_hook slop-scan-pretool.sh "$P" 1 "$PROJ"
assert "slop gate STRICT: banned phrase blocks with exit 2" '[ "$EC" -eq 2 ]'
assert "slop gate STRICT: block reason is on stderr" 'printf "%s" "$ERR" | grep -q "RDLC SLOP GATE"'

run_hook slop-scan-pretool.sh "$P" 0 "$PROJ"
assert "slop gate SOFT: banned phrase warns with exit 1 (non-blocking)" '[ "$EC" -eq 1 ]'
assert "slop gate SOFT: warning is on stderr" 'printf "%s" "$ERR" | grep -q "RDLC SLOP GATE"'

P=$(payload_write "$PROJ/research/notes.md" "$CLEAN_CONTENT")
run_hook slop-scan-pretool.sh "$P" 1 "$PROJ"
assert "slop gate: clean content passes silently (exit 0)" '[ "$EC" -eq 0 ] && [ -z "$OUT$ERR" ]'

# Allowlist suppression through the hook's sed path
printf 'cutting-edge paradigm\ndeep dive\n' > "$PROJ/.rdlc/slop-allowlist.txt"
P=$(payload_write "$PROJ/research/notes.md" 'A deep dive into the cutting-edge paradigm approach.')
run_hook slop-scan-pretool.sh "$P" 1 "$PROJ"
assert "slop gate: allowlisted phrases are suppressed (exit 0)" '[ "$EC" -eq 0 ]'
rm -f "$PROJ/.rdlc/slop-allowlist.txt"

# --- confidence-required.sh --------------------------------------------------

P=$(payload_write "$PROJ/research/notes.md" "$CLEAN_CONTENT")
run_hook confidence-required.sh "$P" 1 "$PROJ"
assert "confidence gate STRICT: unlabeled claims block with exit 2" '[ "$EC" -eq 2 ]'
assert "confidence gate STRICT: block reason is on stderr" 'printf "%s" "$ERR" | grep -q "RDLC CONFIDENCE GATE"'

run_hook confidence-required.sh "$P" 0 "$PROJ"
assert "confidence gate SOFT: unlabeled claims warn with exit 1" '[ "$EC" -eq 1 ]'

P=$(payload_write "$PROJ/research/notes.md" "$LABELED_CONTENT")
run_hook confidence-required.sh "$P" 1 "$PROJ"
assert "confidence gate: labeled content passes (exit 0)" '[ "$EC" -eq 0 ]'

# Word-boundary check: GAP/DIRECT inside other words must NOT satisfy the label
P=$(payload_write "$PROJ/research/notes.md" "$SINGAPORE_CONTENT")
run_hook confidence-required.sh "$P" 1 "$PROJ"
assert "confidence gate: label substring inside words does not bypass (SINGAPORE/GAPINDUSTRY)" '[ "$EC" -eq 2 ]'

# Path scoping: 'marketresearch/' is not 'research/'
P=$(payload_write "$PROJ/marketresearch/notes.md" "$CLEAN_CONTENT")
run_hook confidence-required.sh "$P" 1 "$PROJ"
assert "confidence gate: does not fire outside research/ or evidence/ (marketresearch/)" '[ "$EC" -eq 0 ]'

# --- source-required.sh ------------------------------------------------------

P=$(payload_write "$PROJ/research/notes.md" "$THREE_PARA_NO_SOURCE")
run_hook source-required.sh "$P" 1 "$PROJ"
assert "source gate STRICT: sourceless paragraphs block with exit 2" '[ "$EC" -eq 2 ]'
assert "source gate STRICT: block reason is on stderr" 'printf "%s" "$ERR" | grep -q "RDLC SOURCE GATE"'

run_hook source-required.sh "$P" 0 "$PROJ"
assert "source gate SOFT: sourceless paragraphs warn with exit 1" '[ "$EC" -eq 1 ]'

P=$(payload_write "$PROJ/research/notes.md" "$THREE_PARA_NO_SOURCE
[Source: https://example.gov/minutes]")
run_hook source-required.sh "$P" 1 "$PROJ"
assert "source gate: sourced content passes (exit 0)" '[ "$EC" -eq 0 ]'

# --- audience-firewall.sh ----------------------------------------------------

# Rule in the hook's own documented format: relative glob
printf 'output/public_*.html|salary range|salary belongs to private prep only\n' > "$PROJ/.rdlc/audience-firewall.conf"
P=$(payload_write "$PROJ/output/public_report.html" 'The salary range is 100k to 120k for this role.')
run_hook audience-firewall.sh "$P" 1 "$PROJ"
assert "firewall STRICT: documented relative glob matches absolute file_path (exit 2)" '[ "$EC" -eq 2 ]'
assert "firewall STRICT: block reason is on stderr" 'printf "%s" "$ERR" | grep -q "RDLC AUDIENCE FIREWALL"'

run_hook audience-firewall.sh "$P" 0 "$PROJ"
assert "firewall SOFT: violation warns with exit 1" '[ "$EC" -eq 1 ]'

# Conf without trailing newline must still enforce its last rule
printf 'output/public_*.html|salary range|salary is private' > "$PROJ/.rdlc/audience-firewall.conf"
run_hook audience-firewall.sh "$P" 1 "$PROJ"
assert "firewall: conf without trailing newline still enforces last rule" '[ "$EC" -eq 2 ]'

# Clean content passes
printf 'output/public_*.html|salary range|salary is private\n' > "$PROJ/.rdlc/audience-firewall.conf"
P=$(payload_write "$PROJ/output/public_report.html" 'The committee published its findings in the spring report.')
run_hook audience-firewall.sh "$P" 1 "$PROJ"
assert "firewall: clean content passes (exit 0)" '[ "$EC" -eq 0 ]'
rm -f "$PROJ/.rdlc/audience-firewall.conf"

# --- fail-open probe ---------------------------------------------------------

P=$(payload_write "$PARTIAL/research/notes.md" "$SLOP_CONTENT")
run_hook slop-scan-pretool.sh "$P" 1 "$PARTIAL"
assert "fail-closed: hooks installed but RDLC.md missing blocks in strict mode (exit 2)" '[ "$EC" -eq 2 ]'
assert "fail-closed: missing-RDLC.md reason is on stderr" 'printf "%s" "$ERR" | grep -qi "RDLC"'

# --- wiring config -----------------------------------------------------------

assert "hooks.json: no dead 'if' keys (not part of the hook schema)" \
  'jq -e "[.. | objects | select(has(\"if\"))] | length == 0" "$HOOKS/hooks.json" >/dev/null'
assert "settings template: no dead 'if' keys" \
  'jq -e "[.. | objects | select(has(\"if\"))] | length == 0" "$ROOT/cli/templates/settings.json" >/dev/null'
assert "hooks.json: PreToolUse matcher is anchored" \
  '[ "$(jq -r ".hooks.PreToolUse[0].matcher" "$HOOKS/hooks.json")" = "^(Write|Edit|MultiEdit)$" ]'
assert "settings template: PreToolUse matcher is anchored" \
  '[ "$(jq -r ".hooks.PreToolUse[0].matcher" "$ROOT/cli/templates/settings.json")" = "^(Write|Edit|MultiEdit)$" ]'
assert "hooks.json and settings template register identical hooks (basename parity)" \
  '[ "$(jq -S "[.hooks | to_entries[] | {e: .key, g: [.value[] | {m: (.matcher // \"\"), c: [.hooks[].command | split(\"/\") | last]}]}]" "$HOOKS/hooks.json")" = "$(jq -S "[.hooks | to_entries[] | {e: .key, g: [.value[] | {m: (.matcher // \"\"), c: [.hooks[].command | split(\"/\") | last]}]}]" "$ROOT/cli/templates/settings.json")" ]'

# --- dead code ---------------------------------------------------------------

assert "rdlc-instructions-check.sh: dead CLAUDE_MODEL nudge branch removed" \
  '! grep -q "MODEL NUDGE" "$HOOKS/rdlc-instructions-check.sh"'

echo ""
echo "=== SUMMARY ==="
echo "PASS: $PASS  /  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
