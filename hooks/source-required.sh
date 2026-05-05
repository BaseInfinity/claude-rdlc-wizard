#!/usr/bin/env bash
# PreToolUse hook on Write/Edit/MultiEdit in research/ or evidence/ directories.
# Checks that new claim-shaped content has at least one source reference
# (URL, PMID, DOI, or [Source: ...] inline citation).
# Soft-warn at v0.1 (RDLC_HOOKS_STRICT=1 promotes to hard-block).

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_find-rdlc-root.sh
source "$HOOK_DIR/_find-rdlc-root.sh"

if ! find_rdlc_root; then
    exit 0
fi

PAYLOAD=""
if [ ! -t 0 ]; then
    PAYLOAD=$(cat)
fi
[ -z "$PAYLOAD" ] && exit 0

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

FILE_PATH=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

case "$FILE_PATH" in
    *research/*|*evidence/*) ;;
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

# Source-shaped patterns: URL, PMID, DOI, [Source: ...], (Source: ...)
HAS_SOURCE=$(printf '%s' "$NEW_CONTENT" | grep -ciE 'https?://|PMID:?[[:space:]]*[0-9]|DOI:?[[:space:]]*10\.|\[Source:|\(Source:|\[VERIFIED:|\[SUPPORTED:' || true)

# Count substantive paragraphs (5+ words ending in period)
PARA_COUNT=$(printf '%s' "$NEW_CONTENT" | awk '
    BEGIN { in_code = 0; count = 0 }
    /^```/ { in_code = !in_code; next }
    in_code { next }
    /^#/ { next }
    /^[[:space:]]*[-*+]/ { next }
    /^[[:space:]]*>/ { next }
    /^[[:space:]]*$/ { next }
    {
        n = split($0, words, /[[:space:]]+/)
        if (n >= 5 && $0 ~ /\./) count++
    }
    END { print count }
')

# If new content has 3+ claim-shaped paragraphs but ZERO sources, flag it
if [ "${PARA_COUNT:-0}" -ge 3 ] && [ "${HAS_SOURCE:-0}" -eq 0 ]; then
    echo ""
    echo "RDLC SOURCE GATE: new content in ${FILE_PATH} has $PARA_COUNT claim-shaped paragraphs but no source references."
    echo "Expected at least one of: URL, PMID, DOI, or [Source: ...] inline citation."
    echo "Source-at-first-mention applies — first appearance of a fact in a research file needs a citation."
    echo "See RDLC.md 'Source Hierarchy' for tier discipline."
    echo ""

    if [ "${RDLC_HOOKS_STRICT:-0}" = "1" ]; then
        exit 2
    fi
fi

exit 0
