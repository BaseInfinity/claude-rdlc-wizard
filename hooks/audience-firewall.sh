#!/usr/bin/env bash
# PreToolUse hook on Write/Edit/MultiEdit in output/ directories.
# Checks that audience-private content is not being added to public deliverables.
# Project defines per-deliverable forbidden patterns in .rdlc/audience-firewall.conf
#
# Conf file format (one rule per line):
#   <deliverable-glob>|<forbidden-pattern>|<reason>
# Example:
#   output/public_*.html|salary range|salary belongs to private interview prep only
#   output/clinical_*.pdf|smoking gun|litigation language inappropriate for clinical PDF
#
# Soft-warn at v0.1 (RDLC_HOOKS_STRICT=1 promotes to hard-block).

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_find-rdlc-root.sh
source "$HOOK_DIR/_find-rdlc-root.sh"

if ! find_rdlc_root; then
    exit 0
fi

PROJECT_DIR="$RDLC_ROOT"
CONF="$PROJECT_DIR/.rdlc/audience-firewall.conf"

# No conf = no rules = nothing to enforce
[ ! -f "$CONF" ] && exit 0

PAYLOAD=""
if [ ! -t 0 ]; then
    PAYLOAD=$(cat)
fi
[ -z "$PAYLOAD" ] && exit 0

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

FILE_PATH=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Only fire on output/ paths
case "$FILE_PATH" in
    *output/*) ;;
    *) exit 0 ;;
esac

NEW_CONTENT=$(printf '%s' "$PAYLOAD" | jq -r '
    [
      (.tool_input.content // empty),
      (.tool_input.new_string // empty),
      (.tool_input.edits[]?.new_string // empty)
    ] | join("\n")
' 2>/dev/null) || NEW_CONTENT=""

[ -z "$NEW_CONTENT" ] && exit 0

VIOLATIONS=()

# Iterate conf rules
while IFS='|' read -r glob pattern reason; do
    [ -z "$glob" ] && continue
    [[ "$glob" == \#* ]] && continue

    # Check if FILE_PATH matches the glob
    case "$FILE_PATH" in
        $glob)
            # Check new content for the forbidden pattern
            if printf '%s' "$NEW_CONTENT" | grep -qiE "$pattern"; then
                VIOLATIONS+=("$pattern → $reason")
            fi
            ;;
    esac
done < "$CONF"

if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    echo ""
    echo "RDLC AUDIENCE FIREWALL: forbidden content detected for $FILE_PATH:"
    printf '  - %s\n' "${VIOLATIONS[@]}"
    echo ""
    echo "Audience-private content cannot leak into this deliverable."
    echo "See RDLC.md 'Audience Firewall' and the project's .rdlc/audience-firewall.conf."
    echo ""

    if [ "${RDLC_HOOKS_STRICT:-0}" = "1" ]; then
        exit 2
    fi
fi

exit 0
