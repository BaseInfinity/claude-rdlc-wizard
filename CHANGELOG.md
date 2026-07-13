# Changelog

All notable changes to claude-rdlc-wizard.

## [0.8.0] - 2026-07-12

### Fable self-enforcement audit (issue #9) — the gates now actually gate

A Fable-led audit (mirroring `claude-sdlc-wizard` #436/#437) traced every hook's exit code on every "should block" branch and found the #436 bug class shipped here too: all four PreToolUse gates printed their warnings to **stdout with exit 0** — invisible on PreToolUse (transcript-only) — and in strict mode blocked with an **empty reason** (message on stdout; only stderr reaches Claude on exit 2).

### Fixed — enforcement

- **All four gates** (`slop-scan-pretool`, `confidence-required`, `source-required`, `audience-firewall`): warnings now go to **stderr**; soft mode exits **1** (non-blocking, visible to the user), strict mode exits **2** (blocks, reason fed back to Claude). Previously soft warnings were invisible and strict blocks were reasonless.
- **`audience-firewall.sh` could never fire**: conf rules use project-relative globs (per the hook's own docs) but Claude Code passes absolute paths — the glob never matched. Paths are now normalized to project-relative before matching. Also: a conf file without a trailing newline silently dropped its last rule; invalid ERE rules are now skipped loudly (stderr) instead of silently.
- **`audience-firewall.conf` was never installed**: `cli/init.js` now drops `.rdlc/audience-firewall.conf` (the hook is documented as inert-until-populated; before this it was inert, period).
- **`confidence-required.sh` label bypass**: any uppercase word containing a label substring (SINGAPORE contains GAP) passed the whole edit. Labels now require standalone-word matching.
- **Path filters tightened**: `*research/*` matched `marketresearch/`; filters are now segment-aware (`*/research/*|research/*`).
- **Fail-open family closed**: strict mode now fails closed (exit 2, stderr reason) when hooks are installed but RDLC.md is missing, or when `jq` is absent — previously enforcement silently vanished. `find_rdlc_root` prefers the harness-provided `CLAUDE_PROJECT_DIR` over walking up from CWD.
- **`templates/slop_scan.sh.template` was a no-op as documented**: `SCAN_PATHS=("${@:-output/ research/ evidence/}")` expands to a single nonexistent path when run with no args — exactly the invocation the docs and the baseline hook prescribe. It scanned nothing and passed. Now defaults to the three paths properly.
- **Hook wiring**: removed dead `"if"` keys (not part of the Claude Code hook schema — path scoping they claimed was fictional) from `hooks/hooks.json` and `cli/templates/settings.json`; anchored the PreToolUse matcher to `^(Write|Edit|MultiEdit)$` (was substring-matching NotebookEdit).
- Removed the dead `CLAUDE_MODEL` nudge branch in `rdlc-instructions-check.sh` (env var the harness never sets, glob bug that mis-fired against the exact model it recommended, and stale Opus 4.7 guidance).

### Fixed — tests (the gaps that let the above ship)

- `tests/test-slop-scan.sh`: the "clean content passes" assert was structurally vacuous (`$?` evaluated against the assert helper's own last command — literally `[ 0 -eq 0 ]` forever); the hard-fail assert passed even when fixture setup failed. Both now capture and assert real exit codes plus output text; setup hard-aborts on failure; added a no-arg-invocation regression case.
- `tests/test-hooks-enforcement.sh` (new): 29 assertions tracing exit codes AND stderr routing for every gate branch — strict block, soft warn, clean pass, fail-closed, wiring parity. Mutation-tested (stderr-routing revert → 7 red; firewall glob revert → 4 red; template revert → 1 red).
- `tests/test-doc-consistency.sh` (new): 84 per-location drift assertions — version stamps across six sites, model guidance (version + codename together, per sdlc-wizard #441), hook-name rename stragglers, banned-phrase list parity, cross-reference resolution.
- `tests/test-cli-complexity.sh`: the README-exclusion assert accepted the exact failure value it claimed to exclude (`deliverables:[3-4]` matches 4); now asserts the exact count.
- `tests/test-hooks.sh`: fixed a vacuous negated assertion; outside-project tests now run with `CLAUDE_PROJECT_DIR` cleared.
- `package.json` gains `npm test` (runs every suite); `.github/workflows/test.yml` (new) runs the full suite on ubuntu + macos — previously **nothing** ran these tests.

### Changed — AI Setup Lanes v3 + GPT-5.6 Sol (issue #10, sync from sdlc-wizard v1.84.0/#441)

- `AI_SETUP_LANES.md` rewritten to v3: four lanes — **A: Sonnet 5 + Fable advisor (recommended)**, B: Opus 4.6 Stability (legacy), C: OpusPlan Hybrid, D: Research Lite — with model-aware effort levels (Sonnet 5 `high` default) replacing blanket `max`.
- Cross-model reviewer: GPT-5.5 → **GPT-5.6 Sol** at `xhigh` (fallback Terra), across `AI_SETUP_LANES.md`, `README.md`, `RDLC.md`, all three presets, and `templates/RDLC.md.template`. Historical citations (PATTERNS, CASE_STUDIES, WIZARD_PLAN) intentionally untouched.
- Added the documented non-default reviewer escalation to `max`/Pro for unusually risky PRs.
- `RDLC.md` gains the Autocompact Tuning section `AI_SETUP_LANES.md` had linked to since v0.7.0 (the link was dangling).

### Fixed — doc drift (17 findings from the docs auditor)

- Version stamps synced to 0.8.0 across `package.json`, `.claude-plugin/plugin.json` (was 0.1.0), `RDLC.md` (was 0.3.2), presets (were 0.6.0), `README.md` (was v0.1.0).
- v0.2.1 hook rename finally propagated to `templates/RDLC.md.template` (two stragglers).
- README lane table regenerated (contradicted `AI_SETUP_LANES.md` on Setup A shape and the Lite driver); "five hooks" → six (rdlc-instructions-check was omitted); `/feedback` → `/feedback-rdlc`; stale deferred-list entries removed (presets, CLI, and npm publish all shipped long ago).
- `cli/init.js` success message pointed at `/setup` (the *SDLC* wizard's skill on paired installs) — now `/setup-rdlc`.
- Preset hook-trigger tables promised paths the shipped hook never watched (`clinical/`, `recalls/`, `tsb/`, `policy_documents/`) — corrected to the real `research/`/`evidence/` scope.
- `skills/update/SKILL.md` no longer defers the CLI check to "when the CLI ships" (it shipped at 0.2.0); stale Step-10 references renumbered; `skills/setup/SKILL.md` fossilized "v0.1.0" strings removed.
- `ARCHITECTURE.md`: repo tree, template table (4 → 6), exit-code semantics, and future-work list brought current.
- CHANGELOG: 0.7.0 entry corrected (described sdlc-wizard routing features that never shipped here); 0.1.1 moved above 0.1.0 (reverse-chronological order).

## [0.7.0] - 2026-06-11

### AI Setup Lanes v2 (ported from sdlc-wizard)

Port of the AI Setup Lanes v2 model-selection guidance from `claude-sdlc-wizard` v1.83.0: three recommended model triads (Research Premium / Research Saver / Research Lite) with billing notes for the June 15 split.

- `AI_SETUP_LANES.md` — v2 lane definitions (advisor/driver/reviewer per lane, when-to-use lists, credit-spend guidance)

*(Corrected 2026-07-12: the original entry claimed setup-skill routing logic that never shipped here — that text was copied from sdlc-wizard's changelog.)*

## [0.6.1] - 2026-05-30

### Fixed — Auto-invoke pattern closes the loop on preset installs

`npx claude-rdlc-wizard init` (v0.6.0) drops a non-empty preset RDLC.md, but the `rdlc-prompt-check.sh` hook only auto-invoked `/setup-rdlc` when RDLC.md was missing or empty. Net effect: presets installed cleanly but bespoke customization never auto-triggered — user had to type `/setup-rdlc` manually, breaking the self-adaptive sdlc-wizard pattern this wizard mirrors.

- `hooks/rdlc-prompt-check.sh` — second trigger added: fires SETUP message when RDLC.md contains `<!-- Setup Date: TBD -->`. The hook now distinguishes "no canonical at all" (missing/empty file) from "canonical installed but not customized yet" (TBD stamp).
- `skills/setup/SKILL.md` — Step 5 now explicitly tells the skill to replace `<!-- Setup Date: TBD -->` with today's date as part of customization. Without the stamp, the skill would auto-invoke forever; this closes the loop.
- `tests/test-hooks.sh` — three new assertions (TBD fires SETUP, filled-in date fires BASELINE, filled-in date does NOT fire SETUP). 22 passing.

End-to-end flow restored: `npx claude-rdlc-wizard init` → restart Claude Code → first prompt → hook detects TBD → auto-invokes `/setup-rdlc` → skill customizes + stamps date → subsequent prompts get BASELINE.

## [0.6.0] - 2026-05-24 (medical) / 2026-05-25 (political + automotive)

### Per-domain presets (v0.6 complete: all 3 detected domains have shipped bundles)

The wizard now installs a domain-specific RDLC.md when the scanner detects strong signals for a known domain. All three domains the scanner already detects (medical-legal, political-research, automotive-audit) ship with full preset bundles. v0.4 (Codex adapter) and v0.5 (cross-validate) are intentionally skipped — Claude-side preset work is higher-leverage than cross-tool plumbing without a new consumer.

### Added — Preset infrastructure

- `cli/init.js` — `resolvePreset()` + `listAvailablePresets()`. Explicit `--preset` overrides auto-detect; auto-detect runs `scanResearch().recommended_domain` and uses the preset if one exists.
- `cli/bin/rdlc-wizard.js` — `--preset <name>` flag (also accepts `--preset=<name>`). Unknown preset exits 2 without writing. `--help` lists available presets.
- `tests/test-cli-preset.sh` — 46 assertions covering all 3 preset files' content, explicit `--preset` for each, auto-detect from synthetic signal repos for each, generic fallback, explicit override of auto-detect, and unknown-preset error.
- `package.json` — adds `presets/` to the `files` array so it ships in the npm tarball.

### Added — `presets/medical-legal/RDLC.md` (from anticheat)

- Two-axis claim labeling: GRADE evidence-quality (Very Low / Low / Moderate / High) alongside VERIFIED/SUPPORTED/INFERRED/UNVERIFIED claim confidence. The split is load-bearing — a VERIFIED claim can rest on GRADE: Very Low evidence (single in vitro study). Source: `CASE_STUDIES.md:178`.
- Tier-1 source hierarchy = primary databases only (DrugBank, ChEMBL, PubChem, openFDA, RxNorm, UNII). PubMed papers move to tier 3.
- Standard medical audience-firewall mapping (clinical / patient / legal / internal deliverables).
- Certification/provider-eligibility queue pattern (`.rdlc/certification-queue.md` with recheck dates).
- Inherited regression checks for known mechanism mislabels (creatine/GABA-A class).

### Added — `presets/political-research/RDLC.md` (from states-project-research)

- VERIFIED/SUPPORTED/INFERRED/UNVERIFIED labels (UNVERIFIED as fourth — political research deals with public records, structurally-unknowable GAP rarely applies).
- Tier-1 source hierarchy = primary public records only (FEC filings, IRS 990 forms, Congressional records, court filings via CourtListener/PACER). OpenSecrets/FollowTheMoney drop to tier 3 — they aggregate primary data and drift.
- Multi-audience interview-prep firewall: internal/mock vs subject-facing vs sponsor-facing vs public, with mock-interview/salary/probe-for content permanently firewalled from subject-facing deliverables.
- Three-round Codex review protocol (factual / audience-as-reviewer / stakes-aware) mandatory for subject-facing material.
- Leak-regression class: every time mock-interview or salary content leaked into a subject-facing draft, the assertion becomes permanent.

### Added — `presets/automotive-audit/RDLC.md` (from tucson-investigation)

- Four-label split with GAP as first-class: DIRECT (first-hand observation) / SUPPORTED (TSB/recall) / INFERRED (deduction from DIRECT+SUPPORTED) / GAP (record structurally doesn't exist — distinct from UNVERIFIED).
- Tier-1 source hierarchy = manufacturer TSBs by ID + NHTSA recall PDFs by number. Forum threads quote TSBs; cite the TSB itself.
- Multi-audience firewall plus **methodology-leak gate**: dealer-facing and public deliverables must contain ZERO mentions of investigation methodology. Enforced at generator + regression-suite level.
- Persona-based regression tests via Playwright (`tests/test_personas.py` pattern) — each HTML deliverable walked from the perspective of its target persona (owner / mechanic / dealer).
- Up to 9 Codex review rounds for dealer-audit material (vs. 2-3 for diagnostic) — every round catches a real issue until the dealer-side counterpart can't find a foothold.

### Tests

- 46 preset assertions (was 21 in initial medical-legal ship); all existing suites still green (init 40, scan 28, check 12, complexity 13, hooks 19, templates 6). Total: 164 assertions passing.

### Not addressed

- `tests/test-slop-scan.sh` has pre-existing unset-variable issues in subshells (fails on `main` before this change). Flagged for separate cleanup.
- Journalism preset — scanner doesn't detect it yet (no JDLC case study in flight).
- Legal-only signal detection (NDA/MSA/contract clauses) — current `medical-legal` preset name implies both, but the scanner only detects medical signals. Pure-legal repos like `contract-review-kit` install the generic RDLC.md. Naming/scope decision deferred.

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
