# AI Setup Lanes

Three recommended AI setups for this repo. Setups A and B are complete triads: **planner → driver → reviewer**. Setup C is a lightweight driver-only lane for operational grunt work.

This is **guidance, not a hard rule**. Maintainer override is always allowed.

## Setup A — Research Premium

| Role | Model |
|------|-------|
| **Planner** | Claude Code Opus 4.6 max |
| **Driver** | Claude Code Opus 4.6 max |
| **Reviewer** | Codex (GPT-5.5) xhigh |

Quality-first lane for research work. Opus 4.6 max drives both planning (source identification, confidence calibration, methodology design) and drafting (evidence synthesis, deliverable writing); GPT-5.5 xhigh is the cross-model final gate. Model choice never substitutes for source verification — the RDLC's confidence vocabulary and source hierarchy are the load-bearing discipline, not the model.

## Setup B — Research Saver

| Role | Model |
|------|-------|
| **Planner** | Claude Code Opus 4.6 max |
| **Driver** | Claude Code Sonnet (latest available) |
| **Reviewer** | Codex (GPT-5.5) xhigh |

Cost-efficient lane. Keeps Opus 4.6 max as the planning brain — where source evaluation and confidence reasoning matter most — but moves drafting to Sonnet for routine work. GPT-5.5 xhigh still the final reviewer.

## Setup C — Research Lite

| Role | Model |
|------|-------|
| **Planner** | You (the user) |
| **Driver** | Haiku 4.5 ($1/$5 per Mtok) |
| **Driver fallback** | Sonnet 4.6 standard |
| **Reviewer** | None |

For grunt work: data formatting, bibliography management, file organization, template generation, bulk operations. No RDLC discipline needed — just fast cheap execution.

## When to Use Setup A

- Primary research drafting (evidence dossiers, investigation reports)
- Confidence-critical work (source hierarchy decisions, claim verification)
- Cross-referencing multiple sources
- Audience-firewall-sensitive deliverables
- Methodology design or methodology changes
- Anything where source accuracy matters

## When to Use Setup B

- Routine drafting of pre-researched content
- Formatting and structuring existing research
- Documentation
- Test maintenance
- Mechanical edits to existing deliverables

## When to Use Setup C

- Data formatting scripts
- Bibliography management
- File organization, bulk renames
- Template generation
- Config updates

## Final Review Policy

**Setups A and B end at GPT-5.5 xhigh as the cross-model reviewer.** Setup C has no reviewer.

## See Also

- [claude-sdlc-wizard `AI_SETUP_LANES.md`](https://github.com/BaseInfinity/claude-sdlc-wizard/blob/main/AI_SETUP_LANES.md) — Sibling lanes for SDLC
- [codex-sdlc-wizard `AI_SETUP_LANES.md`](https://github.com/BaseInfinity/codex-sdlc-wizard/blob/main/AI_SETUP_LANES.md) — Codex-side equivalent
