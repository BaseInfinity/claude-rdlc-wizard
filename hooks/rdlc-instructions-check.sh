#!/usr/bin/env bash
# SessionStart hook — validates RDLC.md exists and the canonical pieces are in place.
# Soft-fail: nudges the user to run /setup-rdlc but does not block the session.

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_find-rdlc-root.sh
source "$HOOK_DIR/_find-rdlc-root.sh"

if ! find_rdlc_root && ! find_partial_rdlc_root; then
    # Not an RDLC project — silent exit
    exit 0
fi

PROJECT_DIR="${RDLC_ROOT:-$PWD}"

# Surface gaps without blocking session start
MISSING=()

[ ! -s "$PROJECT_DIR/RDLC.md" ] && MISSING+=("RDLC.md")
[ ! -d "$PROJECT_DIR/.claude/hooks" ] && MISSING+=(".claude/hooks/")
[ ! -f "$PROJECT_DIR/scripts/slop_scan.sh" ] && [ ! -f "$PROJECT_DIR/scripts/regression_test.sh" ] && MISSING+=("scripts/ (regression_test.sh, slop_scan.sh)")

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo "RDLC PARTIAL SETUP — missing: ${MISSING[*]}"
    echo "Run /setup-rdlc to complete installation."
    echo ""
fi

# Recommended model + effort nudge for research work (mirrors sdlc-wizard's
# model-effort-check). Research benefits from Opus 4.7 max + xhigh review.
if [ -n "${CLAUDE_MODEL:-}" ]; then
    case "$CLAUDE_MODEL" in
        *opus[1m]*|*opus*4*7*|*opus*4-7*) ;;
        *)
            echo ""
            echo "RDLC MODEL NUDGE: Research work benefits from Opus 4.7 (1M context)."
            echo "Run: /model opus[1m]"
            echo ""
            ;;
    esac
fi
