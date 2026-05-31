#!/usr/bin/env bash
# Light RDLC hook — baseline reminder every prompt (~120 tokens)
# Full guidance in skill: .claude/skills/rdlc/

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_find-rdlc-root.sh
source "$HOOK_DIR/_find-rdlc-root.sh"

# CWD walk-up finds nearest RDLC project (silent exit for non-RDLC dirs)
if find_rdlc_root; then
    PROJECT_DIR="$RDLC_ROOT"
elif find_partial_rdlc_root; then
    PROJECT_DIR="$RDLC_ROOT"
else
    # Not an RDLC project — exit silently (allows wizard hooks to coexist with
    # code-only repos without spurious output)
    exit 0
fi

# Token-bloat fix: when both project + plugin register this hook, plugin yields.
dedupe_plugin_or_project "${BASH_SOURCE[0]}" || exit 0

# Drain stdin if a JSON payload is being passed (UserPromptSubmit can pipe one).
# We don't use it at v0.1.0 but draining prevents downstream pipe issues.
if [ ! -t 0 ]; then
    cat >/dev/null
fi

if [ ! -s "$PROJECT_DIR/RDLC.md" ]; then
    cat << 'SETUP'
RDLC SETUP NOT COMPLETE: RDLC.md is missing or empty.

MANDATORY FIRST ACTION: Invoke Skill tool, skill="setup-rdlc"
Do NOT proceed with research/fact-check/draft tasks until setup is complete.
Tell the user: "I need to run the RDLC setup wizard first to configure research enforcement."
SETUP
    exit 0
fi

# Preset RDLC.md is non-empty but customization still pending. The wizard's
# init step drops a preset (e.g. medical-legal) and stamps `Setup Date: TBD`
# into the metadata header; /setup-rdlc fills that in when customization
# finishes. Treat TBD as "setup not complete" so the skill auto-invokes.
if grep -q '<!-- Setup Date: TBD -->' "$PROJECT_DIR/RDLC.md" 2>/dev/null; then
    cat << 'SETUP'
RDLC SETUP NOT COMPLETE: RDLC.md is installed but not customized (Setup Date: TBD).

MANDATORY FIRST ACTION: Invoke Skill tool, skill="setup-rdlc"
The preset canonical is in place but bespoke customization (source hierarchy
tuning, audience mapping, regression assertions) has not been run yet.
Tell the user: "I need to run the RDLC setup wizard to finish customizing the preset for this repo."
SETUP
    exit 0
fi

cat << 'EOF'
RDLC BASELINE:
1. SOURCE every claim — primary databases first, watchdog/secondary last
2. LABEL every claim — VERIFIED / SUPPORTED / INFERRED / UNVERIFIED
3. SLOP SCAN must pass — bash scripts/slop_scan.sh, zero hits
4. CROSS-MODEL REVIEW for high-stakes deliverables — mission-first handoff
5. AUDIENCE FIREWALL — per-deliverable boundaries enforced in generator
6. EVERY DEFECT → permanent regression test (the ratchet only turns forward)

AUTO-INVOKE SKILL (Claude MUST do this FIRST):
- research/fact-check/draft/refresh-data/cross-validate/audience-review → Invoke: Skill tool, skill="rdlc"
- DON'T invoke for: questions, explanations, reading existing research, simple lookups
- DON'T wait for user to type /rdlc — AUTO-INVOKE based on task type

Workflow phases:
1. PLAN (read RDLC.md, identify claims, source-tier check, state confidence)
2. VERIFY (gather evidence, label confidence, source-at-first-mention)
3. REVIEW (slop scan, audience firewall, self-review, cross-model if high-stakes)
4. SHIP (regenerate deliverables, regression suite green, commit)
5. IMPROVE (every defect → permanent regression assertion)

Quick refs: RDLC.md | scripts/regression_test.sh | .reviews/handoff.json
EOF
