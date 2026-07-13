#!/usr/bin/env bash
# Verifies all templates parse / run cleanly.
# Run: bash tests/test-templates.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES="$ROOT/templates"

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

echo "=== TEMPLATE TESTS ==="
echo ""

# All shell templates have correct shebang
for tmpl in "$TEMPLATES"/*.sh.template; do
  [ -f "$tmpl" ] || continue
  name=$(basename "$tmpl")
  first_line=$(head -n 1 "$tmpl")
  assert "$name has bash shebang" '[ "$first_line" = "#!/usr/bin/env bash" ]'
done

# Python template has python shebang
if [ -f "$TEMPLATES/generate_deliverable.py.template" ]; then
  first_line=$(head -n 1 "$TEMPLATES/generate_deliverable.py.template")
  assert "generate_deliverable.py.template has python3 shebang" '[ "$first_line" = "#!/usr/bin/env python3" ]'

  if command -v python3 >/dev/null 2>&1; then
    assert "generate_deliverable.py.template parses as Python" 'python3 -c "import ast; ast.parse(open(\"$TEMPLATES/generate_deliverable.py.template\").read())"'
  fi
fi

# Markdown templates have at least one ATX header
for tmpl in "$TEMPLATES"/*.md.template; do
  [ -f "$tmpl" ] || continue
  name=$(basename "$tmpl")
  assert "$name has at least one ATX header" 'grep -qE "^#{1,6} " "$tmpl"'
done

# RDLC.md.template has the metadata header
if [ -f "$TEMPLATES/RDLC.md.template" ]; then
  assert "RDLC.md.template has wizard version comment" 'grep -q "RDLC Wizard Version:" "$TEMPLATES/RDLC.md.template"'
fi

echo ""
echo "=== SUMMARY ==="
echo "PASS: $PASS  /  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
