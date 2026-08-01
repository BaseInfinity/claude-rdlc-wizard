#!/usr/bin/env bash
# Doc-consistency regression tests — catches copy drift between duplicated
# guidance (versions, model recommendations, hook names, banned-phrase lists).
# Added by the Fable self-enforcement audit (issue #9); assertion style ported
# from claude-sdlc-wizard's test-doc-consistency.sh (version + codename together,
# per-location, not aggregate "mentions it somewhere").
#
# Run: bash tests/test-doc-consistency.sh
# Requires: jq

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

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
  echo "SETUP FAILED: jq is required" >&2
  exit 1
fi

echo "=== DOC CONSISTENCY TESTS ==="
echo ""

# Live-guidance files: current recommendations live here. Historical records
# (CHANGELOG, CASE_STUDIES, PATTERNS, WIZARD_PLAN, HANDOFF, EXTRACTION_NOTES,
# ROADMAP) are factual records of past runs and are deliberately excluded.
LIVE_FILES=(
  AI_SETUP_LANES.md README.md RDLC.md CLAUDE.md ARCHITECTURE.md
  presets/automotive-audit/RDLC.md presets/medical-legal/RDLC.md presets/political-research/RDLC.md
  skills/rdlc/SKILL.md skills/setup/SKILL.md skills/update/SKILL.md skills/feedback/SKILL.md
  hooks/slop-scan-pretool.sh hooks/confidence-required.sh hooks/source-required.sh
  hooks/audience-firewall.sh hooks/rdlc-prompt-check.sh hooks/rdlc-instructions-check.sh
  templates/RDLC.md.template templates/slop_scan.sh.template
)

# --- 1. Version sync ---------------------------------------------------------

PKG_VERSION=$(jq -r .version package.json)

assert "plugin.json version matches package.json ($PKG_VERSION)" \
  '[ "$(jq -r .version .claude-plugin/plugin.json)" = "$PKG_VERSION" ]'
assert "RDLC.md header comment version matches package.json" \
  'head -1 RDLC.md | grep -qF "RDLC Wizard Version: $PKG_VERSION"'
assert "RDLC.md tracking table version matches package.json" \
  'grep -qE "^\| Wizard Version \| $PKG_VERSION \|" RDLC.md'
assert "README status line matches package.json version" \
  'grep -qF "v$PKG_VERSION" README.md'
for preset in automotive-audit medical-legal political-research; do
  assert "preset $preset header version matches package.json" \
    'head -1 "presets/$preset/RDLC.md" | grep -qF "RDLC Wizard Version: $PKG_VERSION"'
done

# --- 2. Cross-model reviewer: GPT-5.6 Sol everywhere in live guidance --------

for f in "${LIVE_FILES[@]}"; do
  assert "$f: no stale GPT-5.5/GPT-5.4 reviewer guidance" \
    '! grep -qE "GPT-5\.[45]|gpt-5\.[45]" "$f"'
done

# Version number and codename must travel together (a codename-only or
# number-only check passes under a partial swap — sdlc-wizard #441 lesson).
for f in AI_SETUP_LANES.md README.md RDLC.md \
         presets/automotive-audit/RDLC.md presets/medical-legal/RDLC.md presets/political-research/RDLC.md; do
  assert "$f: every GPT-5.6 mention pairs with Sol" \
    '[ "$(grep -o "GPT-5\.6" "$f" | wc -l)" -eq "$(grep -o "GPT-5\.6 Sol" "$f" | wc -l)" ]'
done

# Per-location: reviewer rows and policy lines in the lanes doc
assert "AI_SETUP_LANES.md: three lane tables name Codex (GPT-5.6 Sol) xhigh as reviewer" \
  '[ "$(grep -c "Codex (GPT-5\.6 Sol) xhigh" AI_SETUP_LANES.md)" -ge 3 ]'
assert "AI_SETUP_LANES.md: Final Review Policy names GPT-5.6 Sol xhigh" \
  'grep -q "end at GPT-5\.6 Sol xhigh as the cross-model reviewer" AI_SETUP_LANES.md'
assert "AI_SETUP_LANES.md: fallback chain is Sol → Terra" \
  'grep -q "auto-falls back to Terra" AI_SETUP_LANES.md'
assert "README lane table names GPT-5.6 Sol xhigh" \
  'grep -q "GPT-5\.6 Sol xhigh" README.md'
assert "RDLC.md recommends GPT-5.6 Sol for cross-model review" \
  'grep -q "GPT-5\.6 Sol" RDLC.md'
for preset in automotive-audit medical-legal political-research; do
  assert "preset $preset recommends GPT-5.6 Sol reviewer" \
    'grep -q "GPT-5\.6 Sol" "presets/$preset/RDLC.md"'
done

# --- 3. Lanes v3: Sonnet 5 default driver ------------------------------------

assert "AI_SETUP_LANES.md: Setup A is Sonnet 5 (Recommended)" \
  'grep -q "^## Setup A — Sonnet 5 + Fable Advisor (Recommended)" AI_SETUP_LANES.md'
assert "AI_SETUP_LANES.md: four lanes (Setup D exists)" \
  'grep -q "^## Setup D — " AI_SETUP_LANES.md'
assert "README lane table: Sonnet 5 driver present" \
  'grep -q "Sonnet 5" README.md'
assert "README lane table: no stale Haiku 4.5 lite driver" \
  '! grep -q "Haiku 4\.5" README.md'
assert "RDLC.md recommends Sonnet 5 as primary model" \
  'grep -qE "^\| Recommended Model \|.*Sonnet 5" RDLC.md'

# --- 4. Hook naming: v0.2.1 rename fully propagated ---------------------------

for f in "${LIVE_FILES[@]}"; do
  assert "$f: no stale instructions-loaded-check reference" \
    '! grep -q "instructions-loaded-check" "$f"'
done

# --- 5. Hook count claims match hooks.json ------------------------------------

REGISTERED=$(jq '[.hooks[][].hooks[]] | length' hooks/hooks.json)
assert "hooks.json registers 6 hooks" '[ "$REGISTERED" -eq 6 ]'
assert "README hook description covers rdlc-instructions-check" \
  'grep -q "rdlc-instructions-check" README.md'
assert "CLAUDE.md says six hooks" 'grep -qi "six hooks" CLAUDE.md'
assert "README says six hooks" 'grep -qi "six hooks" README.md'

# --- 6. Banned-phrase list parity ---------------------------------------------

HOOK_PATTERN=$(grep '^HARD_FAIL_PATTERN=' hooks/slop-scan-pretool.sh)
TEMPLATE_PATTERN=$(grep '^HARD_FAIL_PATTERN=' templates/slop_scan.sh.template)
assert "HARD_FAIL_PATTERN identical between hook and template" \
  '[ "$HOOK_PATTERN" = "$TEMPLATE_PATTERN" ]'

PROSE_REF=$(grep -F 'deep dive' RDLC.md | head -1)
for f in templates/RDLC.md.template presets/automotive-audit/RDLC.md presets/medical-legal/RDLC.md presets/political-research/RDLC.md; do
  assert "$f: hard-fail phrase prose line matches RDLC.md" \
    '[ "$(grep -F "deep dive" "$f" | head -1)" = "$PROSE_REF" ]'
done

# --- 7. Cross-references resolve ----------------------------------------------

assert "RDLC.md has the Autocompact Tuning section AI_SETUP_LANES.md links to" \
  'grep -q "^## Autocompact Tuning" RDLC.md'

# --- 8. CLI messaging and install completeness ---------------------------------

assert "cli/init.js tells users to run /setup-rdlc (not /setup)" \
  'grep -q "setup-rdlc" cli/init.js && ! grep -qE "Run /setup[^-]" cli/init.js'
assert "cli/init.js installs audience-firewall.conf (hook is inert without it)" \
  'grep -q "audience-firewall.conf" cli/init.js'

# --- 9. Skills: no fossilized versions or stale step refs ----------------------

assert "setup skill has no hardcoded v0.1.0" '! grep -q "v0\.1\.0" skills/setup/SKILL.md'
assert "update skill no longer defers the CLI check to v0.2+" \
  '! grep -q "At v0.1.0: skip this step" skills/update/SKILL.md'
assert "setup skill smoke-check step reference is not stale (Step 10 → Step 9)" \
  '! grep -q "Step 10 catches typos" skills/setup/SKILL.md'
assert "update skill step reference is not stale" \
  '! grep -q "mirror Step 10 of setup" skills/update/SKILL.md'

# --- 10. ARCHITECTURE.md matches disk ------------------------------------------

assert "ARCHITECTURE.md lists slop-allowlist.txt.template" \
  'grep -q "slop-allowlist.txt.template" ARCHITECTURE.md'
assert "ARCHITECTURE.md lists audience-firewall.conf.template" \
  'grep -q "audience-firewall.conf.template" ARCHITECTURE.md'

echo ""
echo "=== SUMMARY ==="
echo "PASS: $PASS  /  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
