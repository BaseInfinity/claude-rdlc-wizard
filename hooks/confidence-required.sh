#!/usr/bin/env bash
# PreToolUse hook on Write/Edit/MultiEdit in research/ or evidence/ directories.
# Checks that new claim-shaped content includes a confidence label.
# Soft-warn at v0.1 (RDLC_HOOKS_STRICT=1 promotes to hard-block).
#
# Heuristic: a "claim-shaped sentence" is a non-blockquote sentence ending in a
# period, NOT in a list bullet, NOT in a code block, NOT a section header. New
# claims should sit alongside a confidence marker:
#   (VERIFIED|SUPPORTED|INFERRED|UNVERIFIED|GAP|DIRECT)
# either inline or in an immediately-preceding context line.
#
# This is intentionally lenient at v0.1 — many legitimate edits add prose that
# isn't a claim. The hook flags suspicious adds; the user decides.

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

# Only fire on research/ or evidence/ paths
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

# Already has a confidence label? Pass.
if printf '%s' "$NEW_CONTENT" | grep -qE 'VERIFIED|SUPPORTED|INFERRED|UNVERIFIED|GAP|DIRECT'; then
    exit 0
fi

# Heuristic: count non-trivial declarative sentences that aren't bullets, headers, or code.
CLAIM_CANDIDATES=$(printf '%s' "$NEW_CONTENT" | awk '
    BEGIN { in_code = 0; count = 0 }
    /^```/ { in_code = !in_code; next }
    in_code { next }
    /^#/ { next }                  # markdown header
    /^[[:space:]]*[-*+]/ { next }  # list bullet
    /^[[:space:]]*>/ { next }      # blockquote
    /^[[:space:]]*$/ { next }      # blank
    # A claim-shaped sentence has a period and at least 5 words
    {
        n = split($0, words, /[[:space:]]+/)
        if (n >= 5 && $0 ~ /\./) count++
    }
    END { print count }
')

if [ "${CLAIM_CANDIDATES:-0}" -ge 2 ]; then
    echo ""
    echo "RDLC CONFIDENCE GATE: new content in ${FILE_PATH} contains $CLAIM_CANDIDATES claim-shaped sentences but no confidence label."
    echo "Expected one of: VERIFIED / SUPPORTED / INFERRED / UNVERIFIED (or GAP / DIRECT for investigation domains)."
    echo "See RDLC.md 'Confidence Vocabulary' for guidance."
    echo ""

    if [ "${RDLC_HOOKS_STRICT:-0}" = "1" ]; then
        exit 2
    fi
fi

exit 0
