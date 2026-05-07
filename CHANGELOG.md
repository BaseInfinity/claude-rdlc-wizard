# Changelog

All notable changes to claude-rdlc-wizard.

## [0.3.2] - 2026-05-06

### One-shot consumer install

The tucson dogfood revealed three friction points the v0.3.1 setup flow exposed: (1) the `/setup` skill referenced `${CLAUDE_PLUGIN_ROOT}/templates/` which doesn't resolve for CLI installs; (2) the CLI didn't ship `scripts/` or `.rdlc/` at all, so users had to hand-port templates; (3) two stale `~/rdlc/` paths pointed at the retired pattern repo.

After v0.3.2, `rdlc-wizard init` is a complete consumer install in one command — no template-hunting required.

### Added (init now drops these)

- `scripts/regression_test.sh` — fact-regression scaffold with `check_present` / `check_absent` helpers (executable, with TODO markers for project-specific assertions)
- `scripts/slop_scan.sh` — banned-phrase grep over `output/` / `research/` / `evidence/` (executable)
- `scripts/generate_deliverable.py` — multi-deliverable generator scaffold with audience-firewall enforcement
- `.rdlc/slop-allowlist.txt` — project-specific allowlist with comment header
- `.rdlc/version` — current wizard version, written dynamically (used by `/update` for drift detection independent of the RDLC.md metadata header)

### Changed

- `cli/lib/repo-complexity.js` — also counts root-level `*.md` files that have a paired `*.html` or `*.pdf` sibling. Catches the tucson layout (`car_report.{md,html,pdf}` at root, no `output/` dir). Excludes well-known meta docs (README, CHANGELOG, CLAUDE, SDLC, RDLC, etc.) so docs don't get miscounted as deliverables.
- `cli/lib/scan-research.js` — `tooling.regression_test` is now true for any of: `scripts/regression_test.sh`, `tests/` dir, `pytest.ini`, `conftest.py`, or `pyproject.toml` containing `[tool.pytest...]`. Tucson uses pytest for fact regression instead of a bash script.
- `skills/setup/SKILL.md` Steps 6-7 — rewritten to "verify init dropped them" instead of "copy from `${CLAUDE_PLUGIN_ROOT}/templates/`". Step 7 is now the customization step (allowlist + assertions).
- `skills/feedback/SKILL.md` line 101 — replaced `~/rdlc/CASE_STUDIES.md` with the wizard repo's `CASE_STUDIES.md`.
- `skills/rdlc/SKILL.md` reference footer — replaced `~/rdlc/README.md` and `~/rdlc/CASE_STUDIES.md` with the wizard repo's `PATTERNS.md` and `CASE_STUDIES.md`.

### Tests

- `tests/test-cli-init.sh` — 8 new assertions covering scripts/.rdlc/ (40 total, was 32).
- `tests/test-cli-complexity.sh` — 2 new assertions for root-level paired deliverables (13 total, was 11).
- `tests/test-cli-scan.sh` — 2 new assertions for pytest as regression mechanism (28 total, was 26).

## [0.3.1] - 2026-05-06

### Fix: scan was counting wizard infrastructure as research signal

The v0.3.0 dogfood in `~/test-rdlc-consumer/` (which only had wizard files, no actual research) reported `recommended_domain: medical-legal` and `convention_in_use: true` — false positives caused by the wizard's own canonical `RDLC.md` documenting domain presets and confidence labels as examples.

### Changed

- `cli/lib/scan-research.js` — content scans (regex + label counting) now run only on `*.md` files inside `research/`, `evidence/`, `output/`, `sources/`, `.reviews/`. Files at repo root (RDLC.md / CLAUDE.md / AGENTS.md) and in tooling dirs (scripts/ / .claude/ / .rdlc/) are excluded from content scoring — those are wizard or infrastructure files, not research.
- Path-based domain scoring stays broad — path patterns already require a research-shaped directory (e.g., `evidence/policy_documents`) so they can't drift into wizard infrastructure.

### Tests

- `tests/test-cli-scan.sh` — 6 new scope assertions: root-level `.md` files don't score domains or count labels; moving the same content into `research/` does score it. Total scan tests: 26 (was 20).

## [0.3.0] - 2026-05-06

### Setup scan refinement

The `/setup` skill no longer hand-rolls signal detection inline — it calls a new CLI subcommand and consumes structured JSON. This replaces the v0.2 narrative-style scan with a concrete, testable signal map.

### Added

- `cli/lib/scan-research.js` — research signal scanner with four kinds of output:
  - `domain` scores (`medical-legal`, `political-research`, `automotive-audit`, `general-research`) with content + path heuristics; `general-research` carries a baseline 1 to win ties
  - `confidence_labels` counts (`VERIFIED`, `SUPPORTED`, `INFERRED`, `UNVERIFIED`, `GAP`, `DIRECT`) plus a `convention_in_use` flag (true at ≥3 total label hits)
  - `tooling` flags: `sdlc_wizard`, `codex`, `regression_test`, `slop_scan`, `agents_md`, `claude_md`, `rdlc_md`
  - `structure` flags: presence of `evidence/` / `research/` / `sources/` / `output/` / `.reviews/` / `scripts/`
- `rdlc-wizard scan [path]` CLI subcommand emitting the JSON
- `tests/test-cli-scan.sh` — 20 assertions covering empty / political / medical / automotive / labels-in-use / sdlc-paired / nonexistent-path scenarios

### Changed

- `skills/setup/SKILL.md` Step 1 — replaced the narrative directory + content checklist with a single `npx claude-rdlc-wizard scan` call; the rest of the skill consumes that JSON output. Reduces ambiguity (was: "look for these signals"; now: "read these fields").
- Anti-pattern check added: if every domain score except `general-research` is 0, the skill MUST ask the user for the domain rather than silently defaulting to general-research.

## [0.2.1] - 2026-05-05

### Fix: hook name collision with sdlc-wizard

Dogfood install into `states-project-research` (which has `claude-sdlc-wizard` already installed) surfaced a naming collision: both wizards shipped a hook called `instructions-loaded-check.sh`, but with different content and different events (sdlc: `InstructionsLoaded` checks `SDLC.md`+`TESTING.md`; rdlc: `SessionStart` checks `RDLC.md`). On a paired install, rdlc's `SessionStart` event would have fired sdlc's script — silent gate failure.

### Changed

- Renamed `hooks/instructions-loaded-check.sh` → `hooks/rdlc-instructions-check.sh` (script content unchanged)
- Updated all active references: `hooks/hooks.json`, `cli/init.js`, `cli/templates/settings.json`, `tests/test-cli-init.sh`, `tests/test-hooks.sh`, `RDLC.md`, `ARCHITECTURE.md`, `PATTERNS.md`, `EXTRACTION_NOTES.md`
- Historical references in `CHANGELOG.md` (v0.1.0 entry), `WIZARD_PLAN.md`, `HANDOFF.md` left as-is — they describe the pre-rename state accurately

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
