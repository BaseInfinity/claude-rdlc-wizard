#!/usr/bin/env bash
set -euo pipefail

{ # download guard — prevents partial execution if connection drops

# --- Colors (only if terminal) ---
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BOLD=''
    RESET=''
fi

error() { echo -e "${RED}error${RESET}: $*" >&2; exit 1; }
warn()  { echo -e "${YELLOW}warning${RESET}: $*"; }
info()  { echo -e "${BOLD}$*${RESET}"; }

# --- Help ---
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "RDLC Wizard Installer"
    echo ""
    echo "Usage:"
    echo "  curl -fsSL <url> | bash              Install to current project"
    echo "  curl -fsSL <url> | bash -s -- --global  Install CLI globally"
    echo "  curl -fsSL <url> | bash -s -- --pair  Install with claude-sdlc-wizard"
    echo ""
    echo "Options:"
    echo "  --global    Install rdlc-wizard CLI globally via npm"
    echo "  --pair      Also install claude-sdlc-wizard (recommended for research repos)"
    echo "  --help, -h  Show this help message"
    echo ""
    echo "Requires Node.js >= 18 and npm."
    echo ""
    echo "Recommended pairing: a research repo benefits from BOTH wizards installed."
    echo "  - claude-sdlc-wizard handles code quality (TDD, lint, tests)"
    echo "  - claude-rdlc-wizard handles research correctness (sources, confidence, slop, audience)"
    exit 0
fi

# --- Argument parsing ---
INSTALL_GLOBAL=0
INSTALL_PAIR=0
for arg in "$@"; do
    case "$arg" in
        --global) INSTALL_GLOBAL=1 ;;
        --pair)   INSTALL_PAIR=1 ;;
        *) error "Unknown option: $arg (use --help for usage)" ;;
    esac
done

# --- Check Node.js ---
if ! command -v node >/dev/null 2>&1; then
    error "Node.js is required but not found. Install from https://nodejs.org"
fi

NODE_VERSION=$(node -v | sed 's/v//')
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 18 ]; then
    error "Node.js >= 18 required (found v${NODE_VERSION}). Update from https://nodejs.org"
fi

# --- Check npm ---
if ! command -v npm >/dev/null 2>&1; then
    error "npm is required but not found. It ships with Node.js — reinstall from https://nodejs.org"
fi

if ! command -v npx >/dev/null 2>&1; then
    error "npx is required but not found. It ships with npm — reinstall from https://nodejs.org"
fi

# --- Install ---
if [ "$INSTALL_GLOBAL" -eq 1 ]; then
    info "Installing claude-rdlc-wizard globally..."
    npm install -g claude-rdlc-wizard

    if command -v rdlc-wizard >/dev/null 2>&1; then
        echo -e "${GREEN}Installed successfully${RESET}: rdlc-wizard $(rdlc-wizard --version 2>/dev/null || echo "0.1.0")"
        echo ""
        echo "Run in any research repo:"
        echo "  rdlc-wizard init"
    else
        error "Installation completed but rdlc-wizard not found on PATH"
    fi
else
    info "Installing RDLC Wizard to current project..."
    npx -y claude-rdlc-wizard init

    if [ -f ".claude/hooks/rdlc-prompt-check.sh" ] || [ -f "RDLC.md" ]; then
        echo ""
        echo -e "${GREEN}RDLC installed successfully${RESET}"
    else
        error "Installation completed but wizard files not found. Check output above for errors"
    fi

    if [ "$INSTALL_PAIR" -eq 1 ]; then
        echo ""
        info "Also installing claude-sdlc-wizard (--pair)..."
        npx -y agentic-sdlc-wizard init

        if [ -f ".claude/hooks/sdlc-prompt-check.sh" ]; then
            echo -e "${GREEN}SDLC installed successfully${RESET}"
        else
            warn "SDLC pair install reported no files — check output above"
        fi
    else
        echo ""
        info "Recommended: also install claude-sdlc-wizard for code quality"
        echo "  curl -fsSL https://raw.githubusercontent.com/BaseInfinity/claude-sdlc-wizard/main/install.sh | bash"
    fi

    echo ""
    echo "Restart Claude Code to activate hooks: type /exit then claude"
fi

} # end download guard
