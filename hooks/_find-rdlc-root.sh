#!/usr/bin/env bash
# Shared helper — walks up from CWD to find the nearest RDLC.md.
# Sourced by other hooks; not a Claude Code hook entrypoint.
#
# Sets RDLC_ROOT on success.

find_rdlc_root() {
    # Prefer the harness-provided project dir — hooks may run with a CWD
    # that isn't inside the project.
    if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "${CLAUDE_PROJECT_DIR}/RDLC.md" ]; then
        RDLC_ROOT="$CLAUDE_PROJECT_DIR"
        return 0
    fi
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
    if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "${CLAUDE_PROJECT_DIR}/.claude/hooks/rdlc-prompt-check.sh" ]; then
        RDLC_ROOT="$CLAUDE_PROJECT_DIR"
        return 0
    fi
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

# Fire a PreToolUse gate: message to stderr, then exit.
# Strict mode (RDLC_HOOKS_STRICT=1): exit 2 — blocks the tool call; stderr is
# fed back to Claude as the refusal reason. Soft mode: exit 1 — non-blocking;
# stderr is shown to the user as a warning. (exit 0 + stdout is invisible on
# PreToolUse — transcript-only — which is how these gates shipped inert; see
# issue #9 / sdlc-wizard #436.)
rdlc_gate_fire() {
    printf '%s\n' "$@" >&2
    if [ "${RDLC_HOOKS_STRICT:-0}" = "1" ]; then
        exit 2
    fi
    exit 1
}

# Locate the RDLC root or exit: silent allow outside RDLC repos; if hooks are
# installed but RDLC.md is missing, enforcement would silently vanish — warn
# (soft) or fail closed (strict) instead.
rdlc_require_root() {
    if find_rdlc_root; then
        return 0
    fi
    if find_partial_rdlc_root; then
        rdlc_gate_fire "" \
            "RDLC GATE: hooks are installed but RDLC.md is missing — enforcement is off." \
            "Run /setup-rdlc to restore the canonical." ""
    fi
    exit 0
}

# Gates cannot parse the tool payload without jq. Soft mode: silent allow
# (unchanged v0.1 behavior). Strict mode: fail closed rather than silently
# disabling enforcement.
rdlc_require_jq() {
    if command -v jq >/dev/null 2>&1; then
        return 0
    fi
    if [ "${RDLC_HOOKS_STRICT:-0}" = "1" ]; then
        echo "RDLC GATE: jq is required for strict enforcement but is not installed — failing closed." >&2
        exit 2
    fi
    exit 0
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
