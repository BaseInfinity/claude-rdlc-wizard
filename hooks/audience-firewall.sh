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

rdlc_require_root

PROJECT_DIR="$RDLC_ROOT"
CONF="$PROJECT_DIR/.rdlc/audience-firewall.conf"

# No conf = no rules = nothing to enforce
[ ! -f "$CONF" ] && exit 0

PAYLOAD=""
if [ ! -t 0 ]; then
    PAYLOAD=$(cat)
fi
[ -z "$PAYLOAD" ] && exit 0

rdlc_require_jq

FILE_PATH=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Only fire on output/ path segments
case "$FILE_PATH" in
    */output/*|output/*) ;;
    *) exit 0 ;;
esac

# Conf rules use project-relative globs (see format above), but Claude Code
# passes absolute paths — normalize before matching.
REL_PATH="${FILE_PATH#"$PROJECT_DIR"/}"

NEW_CONTENT=$(printf '%s' "$PAYLOAD" | jq -r '
    [
      (.tool_input.content // empty),
      (.tool_input.new_string // empty),
      (.tool_input.edits[]?.new_string // empty)
    ] | join("\n")
' 2>/dev/null) || NEW_CONTENT=""

[ -z "$NEW_CONTENT" ] && exit 0

VIOLATIONS=()

# Iterate conf rules ("|| [ -n ... ]" keeps a final line without a trailing
# newline from being silently dropped)
while IFS='|' read -r glob pattern reason || [ -n "$glob" ]; do
    [ -z "$glob" ] && continue
    [[ "$glob" == \#* ]] && continue

    # Reject invalid ERE rules loudly instead of silently skipping them
    # (grep exits 0/1 for match/no-match, >1 for a bad pattern)
    printf '' | grep -qiE "$pattern" 2>/dev/null
    if [ $? -gt 1 ]; then
        echo "RDLC AUDIENCE FIREWALL: invalid rule pattern skipped: $pattern" >&2
        continue
    fi

    # Check if the (relative) file path matches the rule glob
    case "$REL_PATH" in
        $glob)
            # Check new content for the forbidden pattern
            if printf '%s' "$NEW_CONTENT" | grep -qiE "$pattern"; then
                VIOLATIONS+=("$pattern → $reason")
            fi
            ;;
    esac
done < "$CONF"

if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    VIOLATION_LINES=$(printf '  - %s\n' "${VIOLATIONS[@]}")
    rdlc_gate_fire "" \
        "RDLC AUDIENCE FIREWALL: forbidden content detected for $FILE_PATH:" \
        "$VIOLATION_LINES" "" \
        "Audience-private content cannot leak into this deliverable." \
        "See RDLC.md 'Audience Firewall' and the project's .rdlc/audience-firewall.conf." ""
fi

exit 0
