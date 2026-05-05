# Roadmap

What's queued for claude-rdlc-wizard beyond v0.1.0.

## v0.2 — npm CLI (no public registry yet)

- [ ] `cli/bin/rdlc-wizard.js` — `init`, `check`, `update`, `complexity` commands
- [ ] Local install path (`npm link` for development; npm registry deferred to v1.0)
- [ ] `setup` skill calls the CLI to drop files instead of inline Write loops
- [ ] First non-originating consumer adopts the wizard (graduation candidate)

## v0.3 — Setup scan refinement

- [ ] Replace the v0.1 5-row signal table with a confidence-driven scanner mirroring sdlc-wizard's setup
- [ ] Detect domain (medical/legal vs political vs automotive vs general) from file patterns and propose a preset
- [ ] Auto-detect existing confidence-label conventions; offer to standardize

## v0.4 — Codex adapter

- [ ] `codex-rdlc-wizard` parallel package — `AGENTS.md` + `.codex/hooks.json`
- [ ] Mirrors host-adapter pattern from xdlc/docs/cross-domain-concerns.md
- [ ] First Codex-only RDLC consumer (likely fork of an existing case study)

## v0.5 — Cross-model review automation

- [ ] `/cross-validate` skill — bundles mission-first prompt structure from xdlc/docs/cross-model-review.md
- [ ] Codex CLI integration (handoff.json + response.json + `.reviews/` artifacts)
- [ ] Convergence detection (2-round sweet spot, 3 max, escalate after that)
- [ ] Audience-as-reviewer prompt variant for tone-sensitive deliverables

## v0.6 — Per-domain presets

- [ ] Medical/legal: GRADE-aligned evidence labels, primary-database verification (DrugBank, ChEMBL, PubChem, openFDA)
- [ ] Political/research: VERIFIED/SUPPORTED/INFERRED/UNVERIFIED, source-tier hierarchy
- [ ] Automotive/audit: DIRECT/SUPPORTED/INFERRED/GAP, persona Playwright tests
- [ ] Journalism: TBD — emerges from JDLC parking lot once first journalism case study lands

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
