#!/usr/bin/env bash
# Shared helper — walks up from CWD to find the nearest RDLC.md.
# Sourced by other hooks; not a Claude Code hook entrypoint.
#
# Sets RDLC_ROOT on success.

find_rdlc_root() {
    local dir="${PWD}"
    while [ "$dir" != "/" ] && [ -n "$dir" ]; do
        if [ -f "$dir/RDLC.md" ]; then
            RDLC_ROOT="$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Partial setup detection — if RDLC.md exists but supporting files are missing,
# or vice versa, we want to nudge the user toward /setup-rdlc.
find_partial_rdlc_root() {
    local dir="${PWD}"
    while [ "$dir" != "/" ] && [ -n "$dir" ]; do
        if [ -d "$dir/.claude/hooks" ] && [ -f "$dir/.claude/hooks/rdlc-prompt-check.sh" ]; then
            RDLC_ROOT="$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Plugin-vs-project deduplication.
# When both the project's local hook and the plugin-installed hook fire,
# yield from the plugin so the user only sees the message once.
dedupe_plugin_or_project() {
    local self_path="$1"
    if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
        return 0
    fi
    case "$self_path" in
        "$CLAUDE_PLUGIN_ROOT"*)
            if [ -f "${RDLC_ROOT:-}/.claude/hooks/$(basename "$self_path")" ]; then
                return 1
            fi
            ;;
    esac
    return 0
}
