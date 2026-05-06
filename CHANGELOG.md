# Changelog

All notable changes to claude-rdlc-wizard.

## [0.2.0] - 2026-05-05

### npm CLI

Ports `claude-sdlc-wizard`'s CLI shape to rdlc. The slash-command skills (`/setup`, `/update`, `/feedback`, `/rdlc`) remain the conversational interface; the CLI is the bootstrap layer (terminal-side install + drift detection).

### Added

- `cli/bin/rdlc-wizard.js` — CLI entry, dispatches `init` / `check` / `complexity`
- `cli/init.js` — exports `init()` and `check()`. Idempotent file-drop with smart `.claude/settings.json` merge (preserves user `permissions` / `env` blocks)
- `cli/lib/repo-complexity.js` — research-repo complexity heuristic (`deliverables`, `evidence_dirs`, `research_files`, `sources`, `audiences` signals; PII/stakes override forces `complex`)
- `cli/templates/settings.json` — `$CLAUDE_PROJECT_DIR`-style hook config dropped during `init`
- `tests/test-cli-init.sh` — 32 assertions covering file-drop, executable bits, idempotency, `--help`, `--version`, `--dry-run`
- `tests/test-cli-check.sh` — 12 assertions covering MISSING / MATCH / CUSTOMIZED / DRIFT statuses, `--json` output
- `tests/test-cli-complexity.sh` — 11 assertions covering empty / light / heavy / stakes-override fixtures

### Updated

- `skills/setup/SKILL.md` — Step 4 now delegates skeleton install to `npx claude-rdlc-wizard init`; Step 9 verification uses `npx claude-rdlc-wizard check`. Steps 5-7 (customize RDLC.md, generate scripts, generate `.rdlc/`) stay in the skill — they need scan-driven values the CLI can't infer.
- `package.json` — version bump to `0.2.0`; the existing `bin: cli/bin/rdlc-wizard.js` declaration now resolves to a real file

### Removed from roadmap

- The originally planned `update` CLI subcommand. `check` covers drift detection; rerunning `init --force` covers reinstall. This mirrors how sdlc-wizard ships (no separate `update` subcommand).

## [0.1.0] - 2026-05-04

### Initial bootstrap

Three RDLC case studies cleared the xdlc extraction threshold (anticheat, states-project-research, tucson-investigation). This release ships the wizard skeleton mirroring claude-sdlc-wizard's shape so consumer repos have a single install command.

### Added

- `RDLC.md` — consumer-installable canonical doc with confidence vocabulary (VERIFIED / SUPPORTED / INFERRED / UNVERIFIED), source hierarchy, slop gate, audience-firewall rule
- `skills/rdlc/SKILL.md` — full lifecycle workflow (Plan → Verify → Review → Ship → Improve)
- `skills/setup/SKILL.md` — confidence-driven setup wizard, scans for research signals (`evidence/`, `sources/`, `research/`, confidence markers in markdown)
- `skills/update/SKILL.md` — drift reconciliation with per-file MATCH/CUSTOMIZED/MISSING/DRIFT classification
- `skills/feedback/SKILL.md` — privacy-first GitHub-issue contribution loop
- `hooks/rdlc-prompt-check.sh` — every-prompt RDLC baseline (~120 tokens)
- `hooks/slop-scan-pretool.sh` — PreToolUse Write/Edit gate, blocks AI slop additions
- `hooks/confidence-required.sh` — PreToolUse Write/Edit gate for new claims in research files
- `hooks/source-required.sh` — PreToolUse gate enforcing source-at-first-mention
- `hooks/audience-firewall.sh` — Pre/PostToolUse gate preventing audience-private content from leaking between deliverables
- `hooks/instructions-loaded-check.sh` — SessionStart validation that RDLC.md exists
- `hooks/hooks.json` — hook registration manifest for Claude Code plugin format
- `templates/regression_test.sh.template` — fact regression suite scaffold (ported from states-project-research)
- `templates/slop_scan.sh.template` — banned-phrase grep gate (one-liner)
- `templates/generate_deliverable.py.template` — multi-document generator with audience boundary enforcement
- `templates/RDLC.md.template` — consumer canonical seed
- `install.sh` — one-line installer mirroring sdlc-wizard's pattern
- `package.json` — npm metadata, name `claude-rdlc-wizard`
- `CLAUDE.md`, `ARCHITECTURE.md`, `ROADMAP.md` — repo self-documentation

### Acknowledged

- This release ships before the v1 graduation criteria stated in `PATTERNS.md` (a fourth case study that consumes patterns from this repo). Justification: GDLC followed the same path with `claude-gdlc-wizard` v0.1.0 — the wizard ships *first* so a fourth consumer has something to install. Graduation remains a separate later milestone tied to a non-originating consumer adopting the wizard and producing an earned rule the first three didn't.
- Templates have been ported from source repos (states-project-research's `regression_test.sh`, the slop scan from `SDLC.md`). This contradicts the original v0 rule "Mine them in place" stated in `PATTERNS.md`. The contradiction is intentional: the wizard cannot install patterns that only live in their birth repos. See ARCHITECTURE.md "Why templates were ported."

## [0.1.1] - 2026-05-04

### Consolidated `~/rdlc/` into this repo

Mirrors the GDLC retirement pattern (`~/gdlc/` → `claude-gdlc-wizard`). The standalone `~/rdlc/` pattern-catalog repo was retired the same day v0.1.0 shipped because the wizard now owns the canonical home for both methodology and implementation.

### Added (migrated from retired `~/rdlc/`)

- `PATTERNS.md` — pattern catalog and per-case-study lessons learned (was `~/rdlc/README.md`)
- `CASE_STUDIES.md` — proof-point cross-index + Contributions Inventory (was `~/rdlc/CASE_STUDIES.md`)
- `EXTRACTION_NOTES.md` — v0.1.0 build journal (was `~/rdlc/EXTRACTION_NOTES.md`)
- `WIZARD_PLAN.md` — historical implementation plan, marked superseded (was `~/rdlc/WIZARD_PLAN.md`)
- `HANDOFF.md` — historical pre-build handoff, marked superseded (was `~/rdlc/HANDOFF.md`)

### Updated

- `README.md` — points at in-repo files instead of `~/rdlc/`
- `CLAUDE.md` — same
- `ARCHITECTURE.md` — same
- `ROADMAP.md` — same

### Note

Historical references to `~/rdlc/` inside the migrated files describe the pre-consolidation state and are preserved for context. The retired repo lives at `~/rdlc.archived-2026-05-04/` for recovery; nothing was deleted.
