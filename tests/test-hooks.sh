#!/usr/bin/env bash
# Smoke tests for claude-rdlc-wizard hooks.
# Run: bash tests/test-hooks.sh
# Exit 0 = pass, 1 = fail

set -uo pipefail

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

echo "=== HOOK SMOKE TESTS ==="
echo ""

# All hooks have correct shebang
for hook in "$HOOKS"/*.sh; do
  name=$(basename "$hook")
  first_line=$(head -n 1 "$hook")
  assert "$name has bash shebang" '[ "$first_line" = "#!/usr/bin/env bash" ]'
done

# All hooks are executable
for hook in "$HOOKS"/*.sh; do
  name=$(basename "$hook")
  assert "$name is executable" '[ -x "$hook" ]'
done

# hooks.json is valid JSON
if command -v jq >/dev/null 2>&1; then
  assert "hooks.json parses as valid JSON" 'jq -e . "$HOOKS/hooks.json" >/dev/null'
else
  echo "SKIP: jq not installed, skipping hooks.json validation"
fi

# Slop scan hook does not crash with empty stdin
assert "slop-scan-pretool.sh handles empty stdin" 'echo "" | "$HOOKS/slop-scan-pretool.sh"'

# Slop scan hook does not crash with non-RDLC project (silent exit)
assert "slop-scan-pretool.sh exits 0 outside RDLC project" '(cd /tmp && echo "{}" | "$HOOKS/slop-scan-pretool.sh")'

# rdlc-prompt-check.sh exits silently outside RDLC project
assert "rdlc-prompt-check.sh exits 0 outside RDLC project" '(cd /tmp && "$HOOKS/rdlc-prompt-check.sh" </dev/null >/dev/null)'

# rdlc-instructions-check.sh handles missing RDLC.md
assert "rdlc-instructions-check.sh handles missing RDLC.md" '(cd /tmp && "$HOOKS/rdlc-instructions-check.sh" >/dev/null)'

# rdlc-prompt-check.sh fires SETUP message when RDLC.md has unresolved
# "Setup Date: TBD" marker (i.e., npm init dropped preset but /setup-rdlc never ran)
TMP_TBD=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-hook-tbd-XXXXXX")
cat > "$TMP_TBD/RDLC.md" <<'TBD'
<!-- RDLC Wizard Version: 0.6.0 -->
<!-- Setup Date: TBD -->
<!-- Completed Steps: -->
<!-- Domain: medical-legal -->

# RDLC Configuration — Medical/Legal Preset
Body content so file is non-empty.
TBD
assert "rdlc-prompt-check.sh fires SETUP when Setup Date is TBD" \
  '(cd "$TMP_TBD" && "$HOOKS/rdlc-prompt-check.sh" </dev/null 2>/dev/null | grep -q "RDLC SETUP NOT COMPLETE")'
rm -rf "$TMP_TBD"

# rdlc-prompt-check.sh fires BASELINE (not SETUP) when Setup Date is filled in
TMP_DONE=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-hook-done-XXXXXX")
cat > "$TMP_DONE/RDLC.md" <<'DONE'
<!-- RDLC Wizard Version: 0.6.0 -->
<!-- Setup Date: 2026-05-30 -->
<!-- Completed Steps: 1,2,3,4,5,6,7,8,9,10 -->
<!-- Domain: medical-legal -->

# RDLC Configuration — Medical/Legal Preset
Body content so file is non-empty.
DONE
assert "rdlc-prompt-check.sh fires BASELINE when Setup Date is filled in" \
  '(cd "$TMP_DONE" && "$HOOKS/rdlc-prompt-check.sh" </dev/null 2>/dev/null | grep -q "RDLC BASELINE")'
assert "rdlc-prompt-check.sh does NOT fire SETUP when Setup Date is filled in" \
  '! (cd "$TMP_DONE" && "$HOOKS/rdlc-prompt-check.sh" </dev/null 2>/dev/null | grep -q "RDLC SETUP NOT COMPLETE")'
rm -rf "$TMP_DONE"

echo ""
echo "=== SUMMARY ==="
echo "PASS: $PASS  /  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
