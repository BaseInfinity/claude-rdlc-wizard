# claude-rdlc-wizard

> RDLC enforcement for Claude Code — hooks, skills, and wizard setup for research repos. The research-domain sibling of [claude-sdlc-wizard](https://github.com/BaseInfinity/claude-sdlc-wizard).

**Status:** v0.1.0 (bootstrap, 2026-05-04). Three case studies cleared the xdlc "two case studies → extract" threshold: [anticheat](https://github.com/BaseInfinity/anticheat), [states-project-research](https://github.com/BaseInfinity/states-project-research), [tucson-investigation](https://github.com/BaseInfinity/tucson-investigation). Patterns documented in `~/rdlc/` ([BaseInfinity/rdlc](https://github.com/BaseInfinity/rdlc)).

## What this installs

A research lifecycle on top of any Claude Code project that produces sourced research deliverables — interview prep, medical/legal evidence dossiers, automotive diagnostics, market analyses, anything where claims need sources and confidence levels.

| Layer | What it does |
|-------|--------------|
| `RDLC.md` | Consumer-installable canonical doc — confidence vocabulary, source hierarchy, slop gate, audience-firewall rule |
| `/rdlc` skill | Full lifecycle workflow (Plan → Verify → Review → Ship → Improve) |
| `/setup-rdlc` skill | Confidence-driven setup — scans repo, asks only what it can't detect |
| `/update-rdlc` skill | Drift reconciliation when wizard upgrades |
| `/feedback` skill | Privacy-first contribution loop |
| Hooks | Slop scan, confidence-required, source-required, prompt-check, audience-firewall |
| Templates | `regression_test.sh`, `slop_scan.sh`, multi-deliverable generator scaffold |

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/BaseInfinity/claude-rdlc-wizard/main/install.sh | bash
```

Or scaffold manually:

```bash
npx -y claude-rdlc-wizard init
```

Run inside a research repo. The wizard scans for evidence/sources/confidence-marker patterns and only asks what it can't infer.

## Relationship to claude-sdlc-wizard

Both run in parallel. SDLC handles code quality; RDLC handles research correctness. From `~/xdlc/README.md`:

> SDLC without the domain DLC = clean code that produces wrong output.
> Domain DLC without SDLC = correct requirements built with sloppy code.

A research repo installs both:

```bash
curl -fsSL .../claude-sdlc-wizard/install.sh | bash   # code layer
curl -fsSL .../claude-rdlc-wizard/install.sh | bash   # research layer
```

## Vocabulary mapping (vs SDLC)

| SDLC | RDLC |
|------|------|
| Write failing test | Form hypothesis / define claim |
| Implement feature | Gather evidence / research |
| Run tests (green) | Cross-validate sources |
| Lint / typecheck | Confidence scoring |
| Regression tests | Fact regression tests |
| Code review | Cross-model adversarial review |
| TDD guard hooks | Source verification hooks |

## What's in v0.1.0 vs deferred

**In v0.1.0:**
- Skill triple (`rdlc`, `setup`, `update`, `feedback`)
- Five hooks (prompt-check, slop-scan, confidence-required, source-required, audience-firewall)
- Three templates (regression_test.sh, slop_scan.sh, generate_deliverable.py skeleton)
- RDLC.md consumer canonical
- install.sh + package.json

**Deferred to later versions** (per skills-first rule, earned through use):
- Setup wizard scan logic refinement (starts with the 5-row signal table from xdlc cross-domain-concerns.md)
- Per-domain RDLC presets (medical/legal, political, automotive, journalism)
- Codex adapter (`codex-rdlc-wizard`)
- L-code enumeration (anticheat A–G, tucson L1–L15 — earn RDLC's own through use)
- npm registry publish (currently local install via `npx --prefix` against the cloned repo)

## Documentation

- `RDLC.md` — the consumer canonical that gets installed into target repos
- `CLAUDE.md` — wizard self-instructions (this repo)
- `ARCHITECTURE.md` — how the pieces fit
- `CHANGELOG.md` — version history
- `ROADMAP.md` — what's queued for v0.2 and beyond

## Case studies that proved the patterns

See `~/rdlc/CASE_STUDIES.md` for the full cross-index. Short version:

- **anticheat** (160 commits, 316 tests) — medical/legal evidence aggregation. GRADE-aligned labels, certification queue, compound mechanism verification.
- **states-project-research** (43 commits, 257 bash asserts) — political/interview prep. VERIFIED/SUPPORTED/INFERRED/UNVERIFIED, fact regression suite, multi-deliverable generator with audience firewall.
- **tucson-investigation** (36 commits, 111 tests) — automotive diagnostic + dealer audit. DIRECT/SUPPORTED/INFERRED/GAP, Playwright persona tests, methodology leak gate, 9-round Codex xhigh loop.

## License

MIT
