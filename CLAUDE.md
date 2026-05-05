# claude-rdlc-wizard — Claude Instructions

> **Part of the [XDLC ecosystem](https://github.com/BaseInfinity/xdlc)** — this is the RDLC sibling, installed into research repos as the correctness/evidence layer alongside `claude-sdlc-wizard`'s code-quality layer.
>
> **Skills first → wizard later.** The patterns shipped here were proven across three RDLC case studies (anticheat, states-project-research, tucson-investigation) before extraction. Pattern source: `~/rdlc/README.md` and `~/rdlc/CASE_STUDIES.md`.

## Project Overview

This is a **meta-repository**. It contains the RDLC Wizard documentation, skills, hooks, and templates that get installed into research repos. No application code lives here.

### What this repo contains

- `RDLC.md` — the consumer-installable canonical that gets copied into target repos
- `skills/` — four skills: `rdlc` (the doing-the-work skill), `setup`, `update`, `feedback`
- `hooks/` — five hooks enforcing slop / confidence / source / audience / prompt baseline
- `templates/` — reusable scaffolds (regression test suite, slop scan, multi-deliverable generator)
- `cli/` — npm CLI for `npx claude-rdlc-wizard init` (deferred to v0.2)
- `tests/` — bash + jq fixtures for hook and template behavior

### What this repo does NOT have

- No `/src/` (no application code)
- No build pipeline (markdown, bash, and templates only)
- No traditional unit tests (bash + grep + jq fixtures only)

### Test dependencies

- `bash` (3.x+ on macOS, 4.x+ on Linux)
- `jq` for JSON-payload hooks
- `grep -E` (extended regex) for slop scanning

## Commands

| Command | Purpose |
|---------|---------|
| `bash tests/test-hooks.sh` | Run hook behavior tests |
| `bash tests/test-templates.sh` | Verify template files parse correctly |
| `bash tests/test-slop-scan.sh` | Verify the banned-phrase grep matches expected hits |
| `./install.sh --help` | Installer help |

## Code Style

### Markdown

- ATX headers (`#`, `##`)
- Tables for structured data
- Code blocks with language hints
- Plain language; **no AI slop** (the wizard enforces this on consumers — we hold ourselves to the same standard)

### Bash (Hooks/Tests)

- `#!/usr/bin/env bash` shebang
- `set -euo pipefail` for fail-fast
- Quote variables: `"$VAR"` not `$VAR`
- `$(command)` not backticks
- ERE regex (`grep -E`), not BRE (`grep` with `\|` won't work as expected)

### YAML

- 2-space indentation
- Quote strings with special characters

## Architecture

See `ARCHITECTURE.md` for full details.

Key concepts:
- **Wizard**: skills + hooks + templates that consumer repos install
- **RDLC.md**: canonical doc copied into every consumer repo (analogous to `claude-sdlc-wizard`'s `SDLC.md`)
- **Auto-update**: weekly workflow checks for upstream changes (deferred to v0.2)
- **Hooks**: enforce RDLC gates at tool-use time
- **Skills**: provide detailed guidance when invoked

## Git Workflow

- Branch protection on `main` (PRs required) — to be enabled when repo goes public
- v0.x releases are bootstrap; semantic versioning kicks in at v1.0 (post graduation)
- Conventional commit format: `type(scope): description`
- **No Claude Code attribution in commits** (per project policy)

## Special Notes

This is a **recursive/meta project**:
- The wizard sets up other research repos
- We dogfood the wizard on this repo itself (slop scan applied to our own docs)
- Changes here affect what gets installed everywhere

When modifying:
- Test changes by installing into a sandbox research repo first
- Consider impact on the three originating case studies (anticheat, states-project, tucson)
- Update version tracking in `RDLC.md` and `CHANGELOG.md`

## Relationship to claude-sdlc-wizard

Mirror its shape, not its content. SDLC patterns about TDD-for-code don't translate to research; RDLC patterns about confidence-on-claims don't translate to code. The shared scaffolding (skill triple, install.sh, hooks.json format, package.json layout) carries; the substance diverges by domain.

When sdlc-wizard ships a generic improvement (better hook dedupe, npx cache detection, better update flow), port it. When it ships a code-specific feature (TDD pretool check, lint integration, deploy verification), don't.

## Lessons Learned

(Empty at v0.1.0 — entries earned through real installs into consumer repos.)
