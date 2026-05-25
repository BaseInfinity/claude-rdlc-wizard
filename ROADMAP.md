# Roadmap

What's queued for claude-rdlc-wizard beyond v0.2.0.

## v0.2 — npm CLI ✅ (shipped 2026-05-05)

- [x] `cli/bin/rdlc-wizard.js` — `init`, `check`, `complexity` commands
- [x] Local install path (`npm link` for development; npm registry deferred to v1.0)
- [x] `setup` skill calls the CLI to drop files instead of inline Write loops
- [ ] First non-originating consumer adopts the wizard (graduation candidate — moved to v1.0 gate)

Dropped from the original v0.2 plan: a separate `update` CLI subcommand. `check` covers drift detection; `init --force` covers reinstall. Mirrors sdlc-wizard.

## v0.3 — Setup scan refinement ✅ (shipped 2026-05-06; v0.3.2 = one-shot consumer install)

- [x] Replace the narrative scan list with a confidence-driven scanner mirroring sdlc-wizard's setup — now `cli/lib/scan-research.js` + `rdlc-wizard scan` subcommand
- [x] Detect domain (medical/legal vs political vs automotive vs general) from file patterns and propose a preset — domain scoring with `general-research` baseline ensures sane default
- [x] Auto-detect existing confidence-label conventions; offer to standardize — `confidence_labels` counts + `convention_in_use` flag
- [x] **v0.3.2 (one-shot install):** `init` now drops `scripts/regression_test.sh`, `scripts/slop_scan.sh`, `scripts/generate_deliverable.py`, `.rdlc/slop-allowlist.txt`, and `.rdlc/version` so a fresh consumer install requires zero template-hunting
- [x] **v0.3.2 (heuristic fixes):** complexity counts root-level paired `*.md` deliverables; scan detects pytest as regression mechanism
- [x] **v0.3.2 (path scrubbing):** removed stale `~/rdlc/` references from skills

Setup skill Step 1 reads a structured JSON map instead of executing a narrative checklist. Reduces hallucination surface (the skill can't miss a check the scanner ran). Step 6 now verifies init dropped scaffolds; Step 7 is for project-specific customization.

## v0.4 — Codex adapter

- [ ] `codex-rdlc-wizard` parallel package — `AGENTS.md` + `.codex/hooks.json`
- [ ] Mirrors host-adapter pattern from xdlc/docs/cross-domain-concerns.md
- [ ] First Codex-only RDLC consumer (likely fork of an existing case study)

## v0.5 — Cross-model review automation

- [ ] `/cross-validate` skill — bundles mission-first prompt structure from xdlc/docs/cross-model-review.md
- [ ] Codex CLI integration (handoff.json + response.json + `.reviews/` artifacts)
- [ ] Convergence detection (2-round sweet spot, 3 max, escalate after that)
- [ ] Audience-as-reviewer prompt variant for tone-sensitive deliverables

## v0.6 — Per-domain presets (in progress; medical-legal shipped 2026-05-24)

- [x] **Medical/legal (shipped 2026-05-24, v0.6.0):** Two-axis labeling (GRADE evidence-quality × VERIFIED/SUPPORTED claim-confidence), primary-database tier-1 (DrugBank, ChEMBL, PubChem, openFDA, RxNorm, UNII), standard audience-firewall mapping (clinical/patient/legal/internal), certification queue pattern. Auto-installed via `init` when the scanner detects medical signals, or explicitly via `init --preset medical-legal`. Source: anticheat case study.
- [ ] Political/research: VERIFIED/SUPPORTED/INFERRED/UNVERIFIED, source-tier hierarchy (FEC/Congress tier-1). Scanner already detects; preset bundle deferred until earned.
- [ ] Automotive/audit: DIRECT/SUPPORTED/INFERRED/GAP, persona Playwright tests. Scanner already detects; preset bundle deferred until earned.
- [ ] Journalism: TBD — emerges from JDLC parking lot once first journalism case study lands

**v0.6 ship pattern (established by medical-legal):** `presets/<name>/RDLC.md` is a full canonical (not an overlay). `init` auto-installs the preset when `scanResearch().recommended_domain` matches and the preset exists; `--preset <name>` overrides. Future presets follow the same shape — copy the medical template, retune Source Hierarchy + audience mapping + regression assertions for the domain.

## v1.0 — Graduation

Per xdlc skill-triple pattern doc, framework graduation requires:
- A second consumer (non-originating) produces an earned rule the originating consumers didn't
- Wizard ships from npm registry
- Cross-tool: Claude Code + Codex + at least one other agent host validated

When v1.0 ships:
- `PATTERNS.md` v1 graduation criteria officially met (originally stated in the retired `~/rdlc/README.md`)
- Promote to public registry, update RDLC row in `~/xdlc/README.md` framework status table

## Deferred experiments (parked from rdlc README)

| Experiment | Hypothesis | Parked since |
|-----------|------------|--------------|
| Deep Research vs DLC stack benchmark | ChatGPT Deep Research is a draft generator that fails L5/L12 gates | 2026-04-15 |

Not scheduled. Run only when an active research repo has bandwidth and produces a clean before/after artifact.

## Anti-roadmap (explicitly NOT planned)

- **Auto-merge or auto-deploy hooks.** Same reason claude-sdlc-wizard refused: the shepherd loop IS the process.
- **Free-form feedback collection.** Structured taxonomy or nothing (per xdlc skill-triple pattern).
- **Web UI.** This is a CLI/skill wizard. Web tooling for research belongs in the deliverable, not the wizard.
- **Generative content production.** The wizard enforces correctness; it does not write the research. The user (with Claude Code) does the research; the wizard guards it.
