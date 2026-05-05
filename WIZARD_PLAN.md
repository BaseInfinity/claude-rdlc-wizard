# claude-rdlc-wizard — Implementation Plan (HISTORICAL)

> **Status (2026-05-04, post-build):** SUPERSEDED. This plan was written before v0.1.0 shipped (same day, earlier session). The Build Gate, Open Decisions, and Build Sequence below describe the *original plan* — the actual v0.1.0 release deviated in several ways (e.g., 4 base skills shipped instead of waiting for graduation; namespace-by-plugin chosen for skill prefixes; templates ported despite "mine in place" rule). See `EXTRACTION_NOTES.md` § "Two rules from the v0 scope that got superseded by the build" for the actual build deltas. Preserved here for the original reasoning.

> **Original status (2026-05-04, pre-build):** Planning only. **Not built yet, on purpose.** Per xdlc skills-first → wizard-later, the four case studies (anticheat, states-project-research, tucson-investigation, plus whichever fourth lands) are still doing the work that proves what's actually portable. This document is the implementation-ready plan another Claude (or human) can pick up and build.
>
> **Reference wizard:** [`claude-sdlc-wizard`](https://github.com/BaseInfinity/claude-sdlc-wizard) (`~/sdlc-wizard/`, version 1.68.0). The RDLC wizard is shaped as a sibling, not a fork.
>
> **Reference patterns:** [`README.md`](README.md) (the v0 pattern catalog) and [`CASE_STUDIES.md`](CASE_STUDIES.md) (the proof points).

---

## Build Gate (when to actually start)

Do NOT start writing wizard code until **all** of these hold. The gates are reproductions of xdlc's skills-first rule — skipping them is how you ship the wrong abstraction.

1. **Fourth RDLC case study consumes patterns from `~/rdlc/`** (not just from one of the three source repos). Per `~/rdlc/README.md` v0 graduation criteria.
2. **At least 2 of the 3 existing case studies have promoted their local skill set into a portable form.** Today they're all path-coupled (states' `tdd-fix` hardcodes `output/interview_prep_document.md`; anticheat's `setup` is currently the SDLC-wizard fork; tucson has only `adlc`). Portable shape = `$ARGUMENTS`-driven, no hardcoded paths, runs against detected files.
3. **The banned-phrase list, source-tier hierarchy, and confidence vocabulary are unified** in this repo (see `Open Decisions` below — these are the three biggest unresolved design points).
4. **One full XDLC graduation ceremony has been run on RDLC** — meaning a fourth case study earns a rule absent from the three existing case studies' ratchets, `grep`-verified per `~/xdlc/README.md` § Graduation-Gate Verification Protocol.

If any one of those is missing, **stop and write more skills in the source repos instead.** The wizard is bookkeeping; the value is in the loops the skills enforce.

---

## Wizard Scope (parallel to sdlc-wizard)

Same shape, different domain.

| Layer | sdlc-wizard | claude-rdlc-wizard |
|-------|-------------|---------------------|
| Plugin manifest | `.claude-plugin/plugin.json` + `marketplace.json` | identical pattern, different name + keywords |
| Reference doc (the monster) | `CLAUDE_CODE_SDLC_WIZARD.md` (~223KB) | `CLAUDE_CODE_RDLC_WIZARD.md` — templates, banned-phrase canon, source-tier table, audience-boundary recipes |
| Base skills | `setup` / `sdlc` / `update` / `feedback` | `setup` / `research` / `update` / `feedback` (same names where they generalize, `research` replaces `sdlc` as the day-to-day workflow skill) |
| Domain skills | none — SDLC is the only workflow | `verify-claim`, `verify-source`, `cross-validate`, `audience-review`, `tdd-fix-prose`, `codex-review`, `slop-scan`, `drift-scan`, `certify` |
| Hooks | 3 (instructions-loaded, prompt-check, tdd-pretool) | 4-5 (instructions-loaded, prompt-check, source-required-on-claim, slop-scan-on-edit, audience-firewall-check) |
| Settings template | TDD enforcement, ruff allowlist | source-verification, slop-scan, audience-firewall, drift-gate |
| Generated files in target repo | `CLAUDE.md`, `SDLC.md`, `TESTING.md`, `ARCHITECTURE.md`, `BRANDING.md`, `DESIGN_SYSTEM.md` (UI-only) | `CLAUDE.md`, `RDLC.md`, `TESTING.md`, `ARCHITECTURE.md`, `BRANDING.md`, `EVIDENCE_STANDARDS.md`, `SOURCE_HIERARCHY.md`, `AUDIENCE_BOUNDARIES.md` (multi-deliverable only) |

**The RDLC wizard does NOT replace `sdlc-wizard`.** Both install. SDLC handles code quality (TDD, tests, ruff). RDLC handles research correctness (sources, confidence, audience). This is the dual-lifecycle pattern proven in `tucson/SDLC_ADLC.md`, `pdlc/CLAUDE.md`, and `anticheat`'s parallel content+code SDLC.

---

## Skill Skeleton (target shape, not a finished spec)

### Base 4 (mirrors sdlc-wizard)

| Skill | Purpose | Invocation |
|-------|---------|------------|
| `setup` | Confidence-driven scan of a research project. Detects: deliverable count, evidence dir, citation density, audience count (1 vs N), data-extraction scripts, regression test pattern. Generates the file set above. | `/research-setup` |
| `research` | Day-to-day workflow skill. Equivalent to sdlc-wizard's `/sdlc`. Steps: state confidence → grade evidence → write claim → cross-validate → write fact regression → run gates → cross-model review → ship. | `/research` |
| `update` | Smart update of installed wizard files; shows changelog, diffs the user's customizations, lets them adopt selectively. Pattern lifted verbatim from sdlc-wizard. | `/research-update` |
| `feedback` | Privacy-first contribution loop. Same pattern as sdlc-wizard's. | `/research-feedback` |

### Domain skills (harvested from case studies)

| Skill | Source | Notes |
|-------|--------|-------|
| `verify-claim` | new | Take a claim, find sources, assign confidence label. Mentioned in README "Skills It Would Provide". |
| `verify-source` | new | Validate URL is live + classify reliability tier. README "Skills". |
| `cross-validate` | states' `codex-review` (generalized) | Run adversarial review on findings; mission-first prompt pattern from anticheat. README "Skills". |
| `audience-review` | new (anticheat-pattern, see Pattern #7 + Pattern #10 in xdlc README) | Cross-model review where reviewer adopts the target audience's mindset. README "Skills". |
| `tdd-fix-prose` | states' `tdd-fix` (port: replace hardcoded paths with `$ARGUMENTS` + auto-detect) | Write failing regression assertion → fix → green → regenerate. Tucson's `.claude/skills/README.md` line 31-34 already documents the port plan. |
| `codex-review` | states' `codex-review` (port: replace hardcoded `output/interview_prep_document.md`) | Mandatory invocation: `-m gpt-5.4 -c 'model_reasoning_effort="xhigh"' -s danger-full-access`. Memory: `~/.claude/projects/-Users-stefanayala-tucson-investigation/memory/feedback_codex_reasoning_effort.md`. |
| `slop-scan` | new (consolidated from states + tucson banned-phrase lists + contract-review-kit's 34 patterns) | grep-based scan + per-project allowlist for legitimate domain vocabulary. README "AI Slop Audit" lessons. |
| `drift-scan` | anticheat (cross-page consistency scanning, see anticheat ROADMAP § "Cross-page drift") | Find all pages containing a claim, check for consistency. README "anticheat skills". |
| `certify` | anticheat (full preflight → handoff → Codex → pickup workflow) | The certification queue pattern. Status machine: IDLE → IN_REVIEW → CERTIFIED/REVIEWED/BLOCKED. |

**Skill UX rule:** every skill takes `$ARGUMENTS`, has a frontmatter `description` that's specific enough Claude picks the right one without the user thinking about it, and never hardcodes a path. Path coupling is the #1 reason existing case-study skills are stuck in their source repos.

---

## Hooks (target)

All bash + jq, mirror sdlc-wizard's pattern. Each hook walks up from CWD to find the nearest `RDLC.md` so monorepos work.

| Hook | Fires on | Purpose |
|------|----------|---------|
| `instructions-loaded-check.sh` | InstructionsLoaded (session start) | Validate `RDLC.md` + `EVIDENCE_STANDARDS.md` exist; warn on partial setup. |
| `rdlc-prompt-check.sh` | UserPromptSubmit | Light reminder (~100 tokens): "every claim → source label, every edit → freshness check, no slop." |
| `source-required-on-claim.sh` | PreToolUse Write/Edit on `*.md` in known reader-facing list | If the diff adds a sentence that looks like a factual claim (regex: `\b\d{4}\b`, `\$\d+`, proper-noun + present-tense verb) and no link/citation appears in the same paragraph, print `additionalContext` reminding to add a source label. Soft-warn, not block. |
| `slop-scan-on-edit.sh` | PreToolUse Write/Edit on `*.md` | Run banned-phrase grep against the new content; if hits, return `additionalContext` listing them. Hard-fail tier blocks; soft-warn tier reports. |
| `audience-firewall-check.sh` | PreToolUse Write/Edit on `*.md` in multi-deliverable repo | Cross-check the deliverable's audience list (from `AUDIENCE_BOUNDARIES.md`) against banned content for that audience. e.g., editing `family-pdf.md` and writing "anosognosia" → warn. |
| `drift-gate.sh` | PreCommit (optional, opt-in via settings) | If `mtime(source.md) > mtime(rendered.html)`, fail with the regen command. |

**Hook design constraint:** every hook must `exit 0` on a non-RDLC project (CWD walk-up returns nothing) — no false positives outside the wizard's installed scope. Same rule as sdlc-wizard hooks.

---

## Templates the Wizard Generates

### `CLAUDE.md` (research-project flavor)

Sections: project mission (1 paragraph) → primary deliverable list → audiences (1 vs N) → evidence dir convention → commands table (regen, regression, slop scan, cross-model review) → code style (if any code) → "Methodology Leak Discipline" section if internal vocabulary needs an allowlist.

Tucson's `CLAUDE.md` is the closest reference — it covers all of these and is a working example.

### `RDLC.md` (the lifecycle rulebook)

Numbered rule list (R1, R2, ... — RDLC's equivalent to ADLC's L-codes). Seed rules (the wizard ships these; the project earns more):

- **R1** — Every claim has a confidence label (see EVIDENCE_STANDARDS.md).
- **R2** — Every claim links to its source OR is explicitly labeled inference.
- **R3** — Every defect found becomes a regression assertion (the ratchet).
- **R4** — Cross-model review required for Class C+ deliverables (severity classes per anticheat REVIEW_MATRIX.md).
- **R5** — Audience boundary enforced per deliverable (see AUDIENCE_BOUNDARIES.md).
- **R6** — Slop scan zero-hits before ship.
- **R7** — Mission context required in every cross-model handoff prompt (anticheat lesson).
- **R8** — Methodology leak grep before reader-facing publish.
- **R9** — Source-tier hierarchy applied (SOURCE_HIERARCHY.md).
- **R10** — Drift gate: derived artifacts (HTML, PDF) regenerated after source edit.

Each rule has an enforcement column: hook / regression test / manual / cross-model. New rules are earned per project, not invented in the wizard.

### `EVIDENCE_STANDARDS.md`

Single canonical taxonomy (see Open Decisions for the unification question). Each label has: name, threshold, examples, what to do when below threshold.

### `SOURCE_HIERARCHY.md`

Project-specific tier table. Wizard ships defaults (official site > government records > peer-reviewed > news > forums) and the user adapts. From states' source hierarchy + anticheat's primary-database-first rule.

### `AUDIENCE_BOUNDARIES.md`

Per-deliverable firewall: which audience reads it, what content is allowed/banned, which test enforces. Only generated if setup detects multi-deliverable + multi-audience. Pattern from anticheat's `generate_pdfs.py` "Bottle Evidence tab" exclusion + states' 12 `check_absent` interview-content tests.

### `TESTING.md` (research-domain template)

Testing Diamond adapted for prose:
- **Base (regression assertions)** — `check_present` / `check_absent` over the rendered output. States' bash pattern OR tucson's pytest pattern, depending on detected stack.
- **Middle (self-review)** — Codex preflight pattern from anticheat.
- **Top (cross-model)** — `/codex-review` skill invocation.

Existing `~/sdlc-wizard/CLAUDE_CODE_SDLC_WIZARD.md` already has domain-adaptive TESTING.md generation (Web/API, Firmware, Data Science, CLI Tool). Add **Research** as a 5th domain.

### `ARCHITECTURE.md`

Single-source → triplet-output pipeline (xdlc Pattern #9). Source markdown → HTML → PDF, with the drift gate. Tucson's `ARCHITECTURE.md` is a working reference.

### `BRANDING.md`

Audience tone notes. Not always needed — generate only if branding/voice assets detected (per sdlc-wizard's setup Step 8.5 logic).

---

## Banned-Phrase Canon (consolidated, must be unified)

Three lists today. The wizard ships **the union** as the default + an opt-out file (`.rdlc-slop-allowlist`) for legitimate domain vocabulary.

**From states-project-research / `~/rdlc/README.md`:**
> deep dive, game-changer, cutting-edge, elevate, unpack, delve, tapestry, holistic, robust, paradigm, groundbreaking, streamline, empower, harness, unleash, pivotal, crucial, bigger picture, smoking gun, in today's world, it's worth noting, at the end of the day

**From tucson-investigation / methodology leak (project-internal vocabulary that shouldn't appear in reader-facing docs):**
> Codex, ADLC, SDLC, xhigh, L[0-9]{2,}, cross-review, ratchet, gate, TDD, regression, gpt-5, model_reasoning

**From anticheat / contract-review-kit (per xdlc README "34 slop patterns"):** harvest exact list at `~/contract-review-kit/<slop-list-file>` when the wizard is built.

**Allowlist mechanism:** per-project `.rdlc-slop-allowlist` file with one phrase per line + optional inline `<!-- slop-ok: <reason> -->` markers. From states' lesson: "Empowering People over Special Interests" is TSP's actual mission pillar; the scan needs proper-noun escape. From tucson's lesson: anchor allowlist on **content** ("OpenAI Codex" exact phrase), not line numbers (line numbers drift).

---

## Confidence Vocabulary (Open Decision — see § Open Decisions)

Three taxonomies in production today; the wizard cannot ship until one wins or they explicitly coexist as presets.

| Source | Taxonomy |
|--------|----------|
| states-project-research | VERIFIED / SUPPORTED / INFERRED / UNVERIFIED |
| tucson-investigation | DIRECT / REPRODUCED / POLICY / INFERRED / EXTERNAL / UNVERIFIED + **6-status** for audit findings (PASS / PASS_WITH_NOTES / CONFIRMED / FAIL / CRITICAL_FAIL / INCONCLUSIVE) |
| anticheat | GRADE-aligned (Very Low / Low / Moderate / High) per evidence type (in vitro / clinical study / systematic review) |

**Recommended resolution (open for review):** ship a "preset selector" in the setup wizard. Domain → preset:
- `political` / `interview-prep` / generic research → states preset
- `automotive` / `consumer-investigation` → tucson preset
- `medical` / `legal-evidence` → anticheat (GRADE) preset
- `general` → states preset (it's the simplest)

The 6-status audit vocabulary (PASS through INCONCLUSIVE) is **separate from** evidence labels — it's for review findings, not claim grading. Both exist together in tucson. The wizard should ship the 6-status vocab as a fixed standard regardless of preset.

---

## Open Decisions (block the build)

1. **Confidence vocabulary unification.** Pick one or ship presets — see above.
2. **Skill prefix collision with sdlc-wizard.** sdlc-wizard's `/setup` and `/update` are the same names RDLC wants. Two options:
   - **Namespace by plugin** (Claude Code already supports `plugin:skill` form) — natural, no collision.
   - **Rename to `/research-setup`, `/research-update`** — explicit, but uglier.
   - **Recommendation:** namespace. Use `claude-rdlc-wizard:setup`. The `setup-wizard` skill from sdlc-wizard's frontmatter `name: setup-wizard` would become `name: research-setup-wizard` to disambiguate at the manifest level.
3. **Hook ordering with sdlc-wizard.** Both wizards install hooks. Need to confirm Claude Code runs them in install order or alphabetical, and write tests that prove no double-firing of the slop-scan when a project also has sdlc-wizard's prompt-check.
4. **Cross-deliverable drift gate scope.** The drift gate enforces `mtime(source) <= mtime(rendered)`. Anticheat's lesson (xdlc Pattern #9 case study) is that this gate is load-bearing precisely because a hand-edited HTML page silently goes stale. But Anticheat's served-page model is different from tucson's regenerated-PDF model. The gate needs to either:
   - Be **opt-in** (project decides at setup time), or
   - **Auto-detect** the pipeline shape (look for a `generate_*.py`, a `Makefile`, a `package.json` build script) and only install the gate if a regen command was found.
5. **Wizard repo location.** Two options:
   - `~/claude-rdlc-wizard/` (matches `~/claude-gdlc-wizard/`, `~/sdlc-wizard/` naming convention — see xdlc Repo Map)
   - Inside `~/rdlc/wizard/` subdir (keeps the patterns + wizard in one repo; matches GDLC's Path A consolidation, xdlc commit `e0c04f2`)
   - **Recommendation:** Path A consolidation. One repo, two products (the README pattern catalog + the wizard distribution). Reduces drift between pattern doc and wizard implementation. xdlc README line 116 calls this pattern out as the GDLC-graduation default.

Resolve all 5 before writing the wizard. Don't punt them into the implementation — they're the actual hard part.

---

## Build Sequence (when gates clear)

This is the order; do not reorder.

1. **Resolve all 5 Open Decisions.** Write the resolutions back into this file.
2. **Port the path-coupled skills to portable form** in their source repos:
   - states' `tdd-fix` → take `$ARGUMENTS` for both the regression file and the target document
   - states' `codex-review` → same
   - anticheat's `setup` is already the SDLC wizard fork; harvest the certification queue pattern as a separate `certify` skill
3. **Harvest canonical templates into `~/rdlc/templates/`** (new dir):
   - `CLAUDE.md.template`, `RDLC.md.template`, `EVIDENCE_STANDARDS.md.template`, `SOURCE_HIERARCHY.md.template`, `AUDIENCE_BOUNDARIES.md.template`, `TESTING.md.template`, `ARCHITECTURE.md.template`
   - Source these from tucson (closest end-to-end working example) + anticheat (multi-audience patterns) + states (regression assertion patterns)
4. **Write `CLAUDE_CODE_RDLC_WIZARD.md`** — the monster reference doc. Mirror the section structure of `~/sdlc-wizard/CLAUDE_CODE_SDLC_WIZARD.md` (read it once, plagiarize the structure, replace SDLC-specific content with RDLC). Include all templates inline.
5. **Write the 4 base skills** (`setup`, `research`, `update`, `feedback`) — port from sdlc-wizard with research-domain swaps.
6. **Write the 5 hooks** — port from sdlc-wizard's hook pattern; `_find-rdlc-root.sh` shared helper.
7. **Write the plugin manifest** (`plugin.json`, `marketplace.json`).
8. **Write the 9 domain skills** (`verify-claim`, `verify-source`, `cross-validate`, `audience-review`, `tdd-fix-prose`, `codex-review`, `slop-scan`, `drift-scan`, `certify`).
9. **Self-test:** install the wizard into `~/anticheat`, `~/states-project-research`, `~/tucson-investigation`, and the fourth case study. Verify no path collision with their existing setups, no double-firing of hooks, and that `/research-setup verify-only` reports green.
10. **Cross-model review** the entire wizard via `codex exec -m gpt-5.4 -c 'model_reasoning_effort="xhigh"' -s danger-full-access` per the mandatory invocation in `~/tucson-investigation/.claude/skills/adlc/SKILL.md`.
11. **Ship v0.1.0** as private. Wait for two real-world installs (not test repos) before tagging v1.0.

---

## What This Plan Is Not

- **Not a roadmap.** No dates. No assigned owners. The skills-first rule means the next step is "use the skills more," not "ship the wizard."
- **Not a spec.** The 9 domain skills above are sketches; their actual shape comes from harvesting working skills in source repos.
- **Not a request to start.** Read the Build Gate above — if any of the four conditions are unmet, **stop and write a skill in a source repo instead.**

---

## Cross-References

- `~/rdlc/README.md` — the pattern catalog (v0)
- `~/rdlc/CASE_STUDIES.md` — proof-point cross-index + (after this commit) the contributions inventory
- `~/rdlc/HANDOFF.md` — short pickup-where-we-left-off doc
- `~/sdlc-wizard/CLAUDE_CODE_SDLC_WIZARD.md` — the canonical wizard reference doc to mirror
- `~/sdlc-wizard/.claude/skills/setup/SKILL.md` — the canonical setup-wizard skill structure
- `~/sdlc-wizard/.claude/hooks/` — hook patterns (instructions-loaded, prompt-check, tdd-pretool)
- `~/xdlc/README.md` § "Skills First → Wizard Later" — the rule this plan obeys
- `~/xdlc/README.md` § "Graduation-Gate Verification Protocol" — how to verify gate #4 before building
- `~/anticheat/REVIEW_MATRIX.md` + `REVIEW_FRAMEWORK.md` — change-class system to harvest
- `~/states-project-research/scripts/regression_test.sh` — bash regression assertion pattern to harvest
- `~/states-project-research/.claude/skills/tdd-fix/SKILL.md` — TDD-for-prose skill to port
- `~/states-project-research/.claude/skills/codex-review/SKILL.md` — Codex review skill to port
- `~/tucson-investigation/ADLC.md` — the L1–L17 ratchet to study (RDLC's R-codes will be similar in shape)
- `~/tucson-investigation/tests/test_personas.py` — persona survival test pattern to harvest
- `~/tucson-investigation/tests/test_build_pipeline.py` — freshness gate pattern to harvest
- `~/tucson-investigation/.claude/skills/README.md` — already documents the port-roadmap for tdd-fix and codex-review

---

**Last updated:** 2026-05-04. **Author:** planning session in `~/tucson-investigation/`. **Pickup:** read `HANDOFF.md` first, then this file, then the Build Gate at the top.
