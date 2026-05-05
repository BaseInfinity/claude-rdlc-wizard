#!/usr/bin/env bash
# PreToolUse hook on Write/Edit/MultiEdit.
# Scans the new content for AI slop banned phrases. Soft-warn at v0.1
# (RDLC_HOOKS_STRICT=1 promotes to hard-block).

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_find-rdlc-root.sh
source "$HOOK_DIR/_find-rdlc-root.sh"

if ! find_rdlc_root; then
    exit 0
fi

PROJECT_DIR="$RDLC_ROOT"

# Banned phrase list (HARD FAIL tier from RDLC.md)
HARD_FAIL_PATTERN='deep dive|game.changer|cutting.edge|elevate|delve|tapestry|holistic|robust|paradigm|groundbreaking|streamline|empower|harness|unleash|unpack|pivotal|crucial|bigger picture|smoking gun|synergy|arguably|it.s worth noting|at the end of the day|in today.s world|needless to say'

# Read JSON payload from stdin (Claude Code passes the tool input here)
PAYLOAD=""
if [ ! -t 0 ]; then
    PAYLOAD=$(cat)
fi

if [ -z "$PAYLOAD" ]; then
    exit 0
fi

# Extract content depending on tool
if ! command -v jq >/dev/null 2>&1; then
    # No jq — can't reliably parse, exit silently
    exit 0
fi

# Concatenate all candidate text fields. Different tools use different field names:
# Write: tool_input.content
# Edit: tool_input.new_string
# MultiEdit: tool_input.edits[].new_string
NEW_CONTENT=$(printf '%s' "$PAYLOAD" | jq -r '
    [
      (.tool_input.content // empty),
      (.tool_input.new_string // empty),
      (.tool_input.edits[]?.new_string // empty)
    ] | join("\n")
' 2>/dev/null) || NEW_CONTENT=""

if [ -z "$NEW_CONTENT" ]; then
    exit 0
fi

FILE_PATH=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Apply project allowlist if it exists
ALLOWLIST="$PROJECT_DIR/.rdlc/slop-allowlist.txt"
FILTERED="$NEW_CONTENT"
if [ -f "$ALLOWLIST" ]; then
    while IFS= read -r line; do
        # Skip empty lines and comments
        [ -z "$line" ] && continue
        [[ "$line" == \#* ]] && continue
        FILTERED=$(printf '%s' "$FILTERED" | sed "s/${line//\//\\/}//gI") || true
    done < "$ALLOWLIST"
fi

# Run the grep
HITS=$(printf '%s' "$FILTERED" | grep -niE "$HARD_FAIL_PATTERN" 2>/dev/null || true)

if [ -n "$HITS" ]; then
    echo ""
    echo "RDLC SLOP GATE: banned phrase(s) detected in new content for ${FILE_PATH:-<unknown>}:"
    echo "$HITS" | head -5
    echo ""
    echo "Rewrite before committing. See RDLC.md 'AI Slop Gate' for the full list and guidance."
    echo "False positive (proper noun, direct quote)? Add the phrase to .rdlc/slop-allowlist.txt"
    echo ""

    if [ "${RDLC_HOOKS_STRICT:-0}" = "1" ]; then
        # Hard-block mode: exit 2 sends stderr to Claude as a tool refusal
        exit 2
    fi
    # Soft-warn: exit 0 but message is visible
fi

exit 0
