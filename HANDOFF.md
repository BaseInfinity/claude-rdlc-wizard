# RDLC Wizard — Handoff (HISTORICAL)

> **Status (2026-05-04):** SUPERSEDED. This handoff was written *before* the v0.1.0 wizard shipped (the same day, earlier session). The "next concrete action" advice below — "if you're here to build the wizard, STOP" — no longer applies because the wizard already exists. Preserved here for historical context. For current state, read `EXTRACTION_NOTES.md` (the build journal) and `CHANGELOG.md`.

> **Originally last updated:** 2026-05-04 from `~/tucson-investigation/` planning session, then extended the same day from `~/anticheat/` post-`gaming-cert-may4-v1` Codex review.
> **For:** the next Claude session (or human) picking this up — **before** v0.1.0 shipped.

## Read in this order

1. **This file** — context + next concrete action.
2. **`README.md`** — what RDLC is, v0 scope, what's in-scope vs explicitly out.
3. **`CASE_STUDIES.md`** — proof points + the new **Contributions Inventory** table (rows mapping artifact → wizard slot → port shape needed).
4. **`WIZARD_PLAN.md`** — the implementation-ready plan. Start at the **Build Gate** at the top. Don't skip it.
5. **`~/xdlc/README.md`** — meta-framework status, framework table, "Skills First → Wizard Later" rule, Graduation-Gate Verification Protocol. Cross-host adapter section in `~/xdlc/docs/cross-domain-concerns.md` is load-bearing for any wizard naming work.

## What's already done

- v0 pattern catalog shipped at `README.md` (2026-04-23).
- 3 case studies indexed at `CASE_STUDIES.md` (anticheat / states-project-research / tucson-investigation).
- Anticheat MDLC trajectory backend shipped Apr 29-30 (Phase A-C, all Codex CERTIFIED) — captured in `CASE_STUDIES.md` §1, but **not** in scope for RDLC wizard. MDLC is a sibling lifecycle, parking lot in xdlc.
- Per-finding `response.json` cross-model review protocol crystallized (anticheat, 9+ rounds) — candidate xdlc Pattern #11.
- Audience-separation rule earned across multiple anticheat reviews — strongest single argument MDLC ≠ RDLC (`CASE_STUDIES.md` §1).
- Cross-host adapter pattern added to `~/xdlc/docs/cross-domain-concerns.md` (uncommitted as of this handoff): `claude-*-wizard` is one host adapter; `codex-*-wizard` is a sibling host adapter, not a fork. Originating consumer owns the first adapter. Extract the Codex adapter after proof, not before.
- `WIZARD_PLAN.md` written (2026-05-04) — implementation-ready, with 4 build gates, 9 domain skills sketched, 5 hooks sketched, 8 templates sketched, 5 open decisions enumerated, 11-step build sequence.
- **Contributions Inventory table added to `CASE_STUDIES.md`** — the harvest map: which artifact in which case study becomes which wizard slot, and what port shape is needed first.

## What's NOT done

- Wizard is **not built**. By design. Per `WIZARD_PLAN.md` § "Build Gate", four conditions must hold first.
- The 5 Open Decisions in `WIZARD_PLAN.md` are not resolved (confidence vocabulary unification, skill-prefix collision, hook ordering, drift-gate scope, repo location).
- The path-coupled skills in `~/states-project-research/.claude/skills/` (`tdd-fix`, `codex-review`) are not yet ported to portable form. This is build-gate condition #2.
- No fourth case study has consumed patterns from `~/rdlc/` yet (build-gate condition #1).
- xdlc registry has not yet been updated to reflect "wizard planning underway." That update is the third pending task in this handoff (see below).
- `WIZARD_PLAN.md` predates the cross-host adapter pattern that landed in `~/xdlc/docs/cross-domain-concerns.md`. The plan still uses `claude-rdlc-wizard` correctly per xdlc commit `d74d7cb`, but it does **not** discuss `codex-rdlc-wizard` as a sibling adapter. Add an addendum if the cross-host pattern starts driving RDLC decisions.

## Next concrete action (pick one)

### If you're here to **build the wizard** — STOP

Re-read `WIZARD_PLAN.md` § "Build Gate". If any of the four conditions is unmet, write a skill in a source repo instead. Building the wizard before re-use means you're guessing at what's portable instead of knowing.

### If you're here to **make progress toward the wizard**

Pick the lowest-blast-radius unblocking work:

1. **Resolve one of the 5 Open Decisions** in `WIZARD_PLAN.md`. The confidence-vocabulary one is the highest-stakes; the skill-prefix collision is the lowest-friction.
2. **Port one path-coupled skill** to portable form in its source repo. `~/states-project-research/.claude/skills/tdd-fix/` is the canonical example — replace `output/interview_prep_document.md` and `scripts/regression_test.sh` with `$ARGUMENTS`. Tucson's `.claude/skills/README.md` line 31-34 already documents the port plan.
3. **Find a fourth case study.** This is the hardest unblock but the highest-leverage: it satisfies build-gate #1 + creates the conditions for graduation-gate #4.

### If you're here because **the user asked to extract a new pattern**

1. Add the pattern to `README.md` under the appropriate "Lessons Learned" section.
2. Add a row to the **Contributions Inventory** in `CASE_STUDIES.md` mapping where it lives → which wizard slot it'd become.
3. If the pattern is convergent across 2+ case studies, also add it to `~/xdlc/README.md` § "Proven Patterns".

### If you're here to **update the xdlc registry**

This is the last pending task from the 2026-05-04 planning session. Update `~/xdlc/README.md` line 136 (the RDLC framework status row) to mention `WIZARD_PLAN.md` exists. Don't bump RDLC's status to "wizard shipped" or anything misleading — it's still v0 patterns + a planning doc. The status line should read something like *"Extracted (2026-04-23); wizard planning at `~/rdlc/WIZARD_PLAN.md` (2026-05-04, build gates not met)"*.

## Cross-references checklist

When picking this up, sanity-check these are still in sync:

- `~/rdlc/README.md` § "What This Will Be" mentions `WIZARD_PLAN.md` exists ✗ (not yet — add)
- `~/rdlc/CASE_STUDIES.md` § "How to Contribute" links to `WIZARD_PLAN.md` ✓
- `~/xdlc/README.md` framework table mentions wizard planning ✗ (next pending task)
- `~/tucson-investigation/.claude/skills/README.md` "Porting roadmap" still names `tdd-fix` and `codex-review` as deferred ✓ (still accurate)

## Memory pointers

The relevant cross-cutting memory entries (per `~/xdlc/README.md` § "Lessons Learned: Mine the Auto-Memory"):

- `feedback_codex_reasoning_effort.md` — never downgrade Codex flags
- `feedback_source_discipline.md` — every claim has a working link
- `project_rdlc_lessons.md` — RDLC lessons from the 14-round audit loop
- `feedback_no_text_blobs.md` — bullet points beat dense paragraphs
- `feedback_ai_slop_review.md` — slop scan must be a formal gate

These memory entries are stored under the **tucson-investigation namespace** (`~/.claude/projects/-Users-stefanayala-tucson-investigation/memory/`). When `~/rdlc/` work moves out of tucson sessions, port the relevant entries into the rdlc namespace so they survive the cross-cut.

---

**Pickup contract:** if you change anything in this file or in the canonical docs (`README.md`, `CASE_STUDIES.md`, `WIZARD_PLAN.md`), update the **Last updated** stamp at the top and add a one-line "What changed" entry below.

## Change log

- **2026-05-04** (Stefan via tucson session) — initial handoff, contributions inventory, planning-state recap.
- **2026-05-04** (Stefan via anticheat session, post-`gaming-cert-may4-v1`) — added four anticheat-perspective contributions to `CASE_STUDIES.md`:
  1. `.claude/skills/sdlc/SKILL.md` row in Contributions Inventory — `$ARGUMENTS`-driven, path-free; closest portable shape for the wizard's `/research` skill body. Includes the load-bearing PreToolUse TDD-CHECK hook ordering note.
  2. Extended the stale-pattern-family row to point at the runnable checker `scripts/preflight.py` + `--strict` mode + ordering rule (run before Codex handoff, not after).
  3. New anti-pattern row: **mechanical sitewide regex pass without paired negative-regression test** (GAMING-004 corruption discovered by Codex `gaming-cert-may4-v1`). Strengthens the existing paired-negative-regression rule with a regex-transform example. Wizard should ship a meta-rule for all `find/replace`/`sed -i` scripts.
  4. Port-shape note on the per-finding `response.json` row — schema gap (no canonical DEFERRED action) discovered when round 1 mixed quick fixes with calibration work needing a separate Codex implementation review_id; the session extended the schema ad-hoc with `deferred_to` + `deferred_findings`. Wizard should canonicalize a fourth action.
