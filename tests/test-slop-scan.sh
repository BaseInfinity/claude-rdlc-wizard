#!/usr/bin/env bash
# Verifies the slop_scan template catches expected hits and respects allowlist.
# Run: bash tests/test-slop-scan.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAN="$ROOT/templates/slop_scan.sh.template"

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

echo "=== SLOP SCAN TESTS ==="
echo ""

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

mkdir -p "$TMP/output"

# --- Case 1: clean content passes ---
cat > "$TMP/output/clean.md" <<'EOF'
# Clean Document

This document contains plain language. No banned phrases here.
The author wrote it carefully and reviewed it for clarity.
EOF

(cd "$TMP" && bash "$SCAN" output/) >/dev/null 2>&1
assert "Clean content passes (exit 0)" '[ $? -eq 0 ]'

# --- Case 2: hard-fail phrase fails ---
cat > "$TMP/output/dirty.md" <<'EOF'
# Dirty Document

Let's deep dive into the cutting-edge paradigm shift.
EOF

set +e
(cd "$TMP" && bash "$SCAN" output/) >/dev/null 2>&1
exit_code=$?
set -e
assert "Hard-fail phrases produce exit 1" '[ $exit_code -eq 1 ]'

# --- Case 3: allowlist suppresses false positive ---
mkdir -p "$TMP/.rdlc"
cat > "$TMP/.rdlc/slop-allowlist.txt" <<'EOF'
# Project-specific
Empowering People over Special Interests
EOF

cat > "$TMP/output/allowlisted.md" <<'EOF'
# Mission Pillar Document

The Empowering People over Special Interests mission pillar guides our work.
The phrase above is a direct quote from the organization's strategic plan.
EOF

set +e
(cd "$TMP" && bash "$SCAN" output/allowlisted.md) >/dev/null 2>&1
exit_code=$?
set -e
# Should pass: the only "empower" hit is in the allowlisted phrase
assert "Allowlist suppresses proper-noun match" '[ $exit_code -eq 0 ]'

echo ""
echo "=== SUMMARY ==="
echo "PASS: $PASS  /  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
