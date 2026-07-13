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

# run_scan <workdir> [args...] — sets EC and OUT; never aborts the suite
run_scan() {
  local dir="$1"; shift
  set +e
  OUT=$( (cd "$dir" && bash "$SCAN" "$@") 2>&1 )
  EC=$?
  set +e
}

echo "=== SLOP SCAN TESTS ==="
echo ""

TMP=$(mktemp -d "${TMPDIR:-/tmp}/rdlc-slop-test-XXXXXX") || { echo "SETUP FAILED: mktemp" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/output" || { echo "SETUP FAILED: mkdir" >&2; exit 1; }

# --- Case 0: no-arg invocation (the documented one) scans the default paths ---
cat > "$TMP/output/dirty.md" <<'EOF'
# Dirty Document

Let's deep dive into the cutting-edge paradigm shift.
EOF

run_scan "$TMP"
assert "No-arg invocation scans default paths and fails on slop (exit 1)" \
  '[ "$EC" -eq 1 ] && printf "%s" "$OUT" | grep -q "hard-tier slop detected"'
rm -f "$TMP/output/dirty.md"

# --- Case 1: clean content passes ---
cat > "$TMP/output/clean.md" <<'EOF'
# Clean Document

This document contains plain language. No banned phrases here.
The author wrote it carefully and reviewed it for clarity.
EOF

run_scan "$TMP" output/
assert "Clean content passes (exit 0)" \
  '[ "$EC" -eq 0 ] && printf "%s" "$OUT" | grep -q "Slop scan PASSED"'

# --- Case 2: hard-fail phrase fails ---
cat > "$TMP/output/dirty.md" <<'EOF'
# Dirty Document

Let's deep dive into the cutting-edge paradigm shift.
EOF

run_scan "$TMP" output/
assert "Hard-fail phrases produce exit 1" \
  '[ "$EC" -eq 1 ] && printf "%s" "$OUT" | grep -q "hard-tier slop detected"'
rm -f "$TMP/output/dirty.md"

# --- Case 3: allowlist suppresses false positive ---
mkdir -p "$TMP/.rdlc" || { echo "SETUP FAILED: mkdir .rdlc" >&2; exit 1; }
cat > "$TMP/.rdlc/slop-allowlist.txt" <<'EOF'
# Project-specific
Empowering People over Special Interests
EOF

cat > "$TMP/output/allowlisted.md" <<'EOF'
# Mission Pillar Document

The Empowering People over Special Interests mission pillar guides our work.
The phrase above is a direct quote from the organization's strategic plan.
EOF

run_scan "$TMP" output/allowlisted.md
# Should pass: the only "empower" hit is in the allowlisted phrase
assert "Allowlist suppresses proper-noun match" '[ "$EC" -eq 0 ]'

echo ""
echo "=== SUMMARY ==="
echo "PASS: $PASS  /  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
