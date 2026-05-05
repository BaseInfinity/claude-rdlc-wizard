# RDLC Case Studies

> **Consolidation note (2026-05-04):** This file was previously `~/rdlc/CASE_STUDIES.md`. Migrated into the wizard repo when `~/rdlc/` was retired (mirrors GDLC retirement pattern). The Contributions Inventory below is now the harvest map for in-repo `templates/`, `skills/`, and `hooks/`.

RDLC earned extraction after three independent projects proved the same research-lifecycle patterns. Each has its own in-repo rulebook; this page is the cross-index.

The extraction rule (from [xdlc/README.md](../xdlc/README.md)): *"When two case studies independently prove the same patterns, extraction pressure is real."* RDLC cleared that bar with three.

> **Scale numbers are point-in-time snapshots.** Test counts and commit counts below are pinned to the SHAs recorded in each case study's "Scale at extraction" line, measured 2026-04-23. Counting methodology differs per repo (pytest-collected vs. bash `grep -qiE` asserts vs. HTTP-response regression asserts) — each entry states which method it uses. Do not treat these as live numbers.

---

## 1. anticheat — Carlos Ayala medical/legal case

**Repo:** `~/anticheat/` (private)
**Domain:** medical-legal evidence aggregation for a family advocacy site
**Lifecycle:** Content SDLC + code SDLC
**Scale at extraction** (pinned to `6a5f9c4`, 2026-04-23): 160 commits on master, 316 pytest-collected tests (of which ~248 are HTTP-response regression tests that hit the served site and assert content, per the lessons section of `~/rdlc/README.md`), 96 research files, 1,200+ citations.

### What it proved

- **Change classification system (A–G)** — not all edits need review; class A (copy/layout) self-checks, class C–F (medical/supplement/legal/mixed) needs full cross-model certification. Encoded in `REVIEW_MATRIX.md`.
- **GRADE-aligned evidence labeling** — every mechanism claim tagged `[in vitro — GRADE: Very Low]` through `[systematic review — GRADE: High]`. Prevents overclaiming at the source.
- **Compound-level mechanism verification** — citation existence alone is insufficient. Creatine was wrongly called "GABA-A agonist" for months because nobody queried ChEMBL/PubChem. Now: every mechanism claim verified against a primary database.
- **Pre-flight self-review before cross-model handoff** — Codex should catch things Claude Code *missed*, not things Claude Code didn't bother to check. Consistently reduced findings to 0–1 per pass.
- **Certification queue workflow** — pages queue for review. Each gets versioned rounds (v1, v2, v3...). Status machine: `IDLE → IN_REVIEW → CERTIFIED | REVIEWED | BLOCKED`.
- **Multi-audience pages from same research base** — same 96 research docs serve clinician pages (conservative), family pages (plain English), litigation pages (advocacy). Audience rules enforced per page.
- **Cross-model reviews need mission context** — sending "review this plan" to Codex gets generic feedback. Sending "THE MISSION: ..., the stakes are ..." gets actionable feedback tied to the actual failure mode.

### Key files to mine

- `anticheat/CLAUDE.md` — Content SDLC + Codex invocation protocol
- `anticheat/REVIEW_FRAMEWORK.md` — audit types, validation gates per change class
- `anticheat/REVIEW_MATRIX.md` — risk classification A–G matrix
- `anticheat/AGENT_REVIEW_LOOP.md` — standard review sequence
- `anticheat/CONTENT_SDLC_AUTOMATION_PLAN.md` — canonical claim registry plan

### Spawned a sibling lifecycle: MDLC (Medical Development Lifecycle)

The Apr 24-26, 2026 substance-risk-window review chain (7 Codex rounds) made it clear that medical/legal advocacy content has lifecycle requirements that don't appear in plain SDLC or CDLC. Documented in `~/anticheat/ROADMAP.md` § "MDLC — Medical Development Lifecycle" and ready for promotion as a sibling pattern alongside SDLC / PDLC / CDLC. Six MDLC stages: evidence ingestion → source triangulation → clinical calibration → cross-model review → audience separation → status communication. Distinctive constraints: audience separation is mandatory (a single-audience doc can be unsafe for the patient even when correct for counsel); pharmacology claims need compound-level verification at DrugBank/ChEMBL/PubChem level; mechanism-based inference must be labeled as such; provider-eligibility verification is operational (a wrong call wastes the urgency window). Open question: dedicated wizard like sdlc-wizard, or stay as documented patterns?

#### MDLC trajectory scoring system shipped (Apr 29-30, 2026)

Tonight's work moved MDLC from "documented stages" to a working backend implementation, end-to-end Phase A through C, all Codex CERTIFIED:

- **Phase A.0** `30f615e` — CUSUM primitive (per-dimension drift detection, bidirectional)
- **Phase A.1 / A.1.5 / A.2** — per-dimension scorers (medication adherence, insight = anosognosia inverse, substance pattern = inverted) + composite + 7-state machine (ACUTE → STABLE_ON_MED → PARTIAL_INSIGHT → FULL_INSIGHT → TAPER_READY → MAINTENANCE; RELAPSE side branch)
- **Phase A.3** `b8a03c9` — orchestrator integrating scorers + CUSUM, persists JSON state
- **Phase A.4** `d7bdc89` — Carlos-relevant chat allowlist (backfill calibration revealed orchestrator was reading 64K Shannon-DM messages and inferring spurious negatives; allowlist of 9 chats fixed RELAPSE-thrash)
- **Phase A.5** `e29663e` — private-observation feed (`evidence/private/carlos_observations_log.jsonl`, JSONL with timestamp / dimension / valence / magnitude / note). Apr 24-29 substance/insight signals now visible to model after backfill calibration showed messages-only scoring missed the most clinically important signals (Stefan's verbal observations, never typed in iMessage)
- **Phase B** `8bd071a` — clinical handoff page auto-trajectory section (`scripts/mdlc_handoff_section.py`, idempotent insert/replace via fence markers; auto-runs after `mdlc_backfill_calibration`)
- **Phase C** `2df97ad` — PreToolUse hard-gate hook (`scripts/pretool_trajectory_check.py`, gates `app/*.html` edits on RELAPSE/ACUTE → block; cusum_low > ALERT_THRESHOLD → warn via JSON `hookSpecificOutput.additionalContext`; otherwise allow). Codex r1 → r3 CERTIFIED with all 6 findings closed (warn-path JSON output, $CLAUDE_PROJECT_DIR-anchored install, MultiEdit coverage, threshold boundary `>` not `>=`, defensive type-checks for malformed state, plan-doc reconciliation)

Test count 530 → 909 across the build-out (380 new tests). All 4 phases pushed to `BaseInfinity/anticheat` main.

The trajectory system is the **clinical calibration** stage of the original 6-stage MDLC framing, made executable. Per Apr 29 backfill calibration on real data, it correctly tracks:

- Mar 4 PHF discharge → STABLE_ON_MED
- Stable Mar/Apr period (no false-positive RELAPSE)
- Apr 24-25 substance escalation (MDMA, alcohol, cocaine apparent access) → substance regression alert
- Apr 29 insight minimization ("small incident", "spreading awareness", "targeted scam" recurrence, Will references) → insight regression alert + state shift PARTIAL_INSIGHT → STABLE_ON_MED

Architectural finding from calibration: the most clinically important signals don't live in messages.db — they're verbal observations Stefan recorded in private notes. The Phase A.5 observation feed closes that gap. This is the kind of insight that's hard to anticipate without backfill calibration on real data; it should be a default step in any future MDLC-style lifecycle (run synthetic-test-passing scoring against ground truth before declaring done).

XDLC extraction status: still parking-lot for the full MDLC framework. Anticheat is one case study; need a second longitudinal-clinical-trajectory case study before promoting to `~/mdlc/`. Open candidates: any future patient or behavioral monitoring system with similar message-corpus + private-observation structure.

#### MDLC's distinctive contribution to cross-model review: per-finding response.json

The Apr 24-30 Codex review chains (7 rounds on the substance-risk-window package, 3 rounds on the Phase C PreToolUse hook) crystallized a per-finding response protocol that's worth lifting into the broader cross-model-review pattern. Standard cross-model review is one-shot ("here's the diff, what do you think") with the author silently fixing whatever they want. That misses two important affordances:

- **Some findings should be disputed, not fixed.** A reviewer can be wrong, or right about a problem but wrong about the solution. Silently rewriting in a way that doesn't address the certify condition leads to recheck rounds spinning indefinitely.
- **Some findings cluster around a single root cause.** Treating them as N independent fixes means you re-derive the root-cause N times.

The pattern: reviewer issues structured findings (ID, severity, certify condition); author writes `.reviews/response.json` with one entry per finding, action ∈ `{FIXED, DISPUTED, ACCEPTED}`:

- **FIXED** — "I fixed this. Here's what changed." Reviewer verifies against the original certify condition.
- **DISPUTED** — "This is intentional/incorrect. Here's why." Reviewer accepts or rejects the justification.
- **ACCEPTED** — "You're right; fixing now." (Same outcome as FIXED, but distinguished so the dialogue records the trajectory honestly.)

Reviewer's recheck round then operates per-finding rather than re-reviewing the whole diff: verify each FIXED against the original certify condition, evaluate each DISPUTED for whether the justification is sound, verify each ACCEPTED was applied. New findings only allowed if P0 (critical/security). Convergence in 2-3 rounds instead of indefinite drift.

Anticheat shipped this protocol in `CLAUDE.md` § "Cross-Model Review Loop" and `~/anticheat/AGENTS.md`; it should be lifted to xdlc as Pattern #11 candidate (per-finding cross-model review protocol with explicit FIXED/DISPUTED/ACCEPTED dialogue) once a second case study exercises it. Anticheat alone has used it across 9+ Codex review chains tonight and across the Apr 24-26 substance package; even single-project use shows convergence behavior is much better than free-form recheck.

#### MDLC's distinctive constraint: audience separation is mandatory

The most surprising MDLC requirement compared to plain SDLC or CDLC: a single document cannot serve all audiences for medical/legal advocacy content. Same underlying evidence renders to different shapes for clinician / litigation / patient / family / regulator audiences, and the rules diverge:

- **Clinician-safe** (`/pcp`, `/supplements`, `/physician-summary` historically): conservative, sourced, GRADE-aligned uncertainty labels, "screen, not assume" framing, no system-failure rhetoric.
- **Litigation-reference** (`/lawyers`, `/evidence`): preponderance standard, calibrated "raises concern" language, no "beyond reasonable doubt", no medical claims dressed as legal conclusions.
- **Patient-facing** (`/carlos`): agency-first ASK framing, no system-failure rhetoric, no substance-use detail, no adversarial framing of caregivers.
- **Family-facing** (`/summary` family/friends tabs): plain English, accessible, no jargon, no acute-medical detail.
- **Regulator-facing** (DMHC parity / CDPH records / HHS OCR HIPAA complaints): statutory specificity, harm articulated against the specific regulator's jurisdiction, no advocacy beyond what the regulator can act on.

The single-audience-document failure mode is asymmetric: a clinician page that's also litigation-toned is unsafe for clinical use (it puts the patient in a defensive posture); a litigation page that's also clinician-toned is just weak legal writing. So the asymmetry forces audience separation to be mandatory rather than optional.

Concrete repo discipline: `app/server.py` route table maps each route to one audience; `tests/test_*.py` regression tests enforce wording that's appropriate to the audience and prohibit drift across the boundary; `scripts/preflight.py` runs cross-page consistency checks but ALSO flags when one page's wording contradicts another's audience constraint. Apr 28's `test_carlos_today_label_date_equal_today` (catches `/carlos` showing yesterday's date) and the persona-aware-design rule in `BRANDING.md` are the operationalization.

For xdlc extraction: this is the strongest single argument that MDLC is a sibling lifecycle, not a SDLC/CDLC variant. SDLC has audiences (developer / user / stakeholder) but they don't conflict structurally; CDLC content audiences are usually the same brand voice across surfaces. MDLC is the lifecycle where audience contradiction is the central design problem.

---

## 2. states-project-research — Interview prep for Liz Chamberlain

**Repo:** `~/states-project-research/` (private)
**Domain:** political/org research, interview preparation for a senior role at The States Project
**Lifecycle:** Research SDLC + code SDLC
**Scale at extraction** (pinned to `fb07fa8`, 2026-04-23): 43 commits on master, 249 `check_present` / `check_absent` bash assertions in `scripts/regression_test.sh`, 24 review rounds with 200+ corrections across the review history. (Earlier drafts quoted 254 — the count drifted downward as some assertions were consolidated; this is exactly the "test counts should be dynamic or verified" anti-pattern the repo itself surfaced.)

### What it proved

- **Source hierarchy with ranked tiers** — official sites > government records > news > professional profiles > watchdog sites. Each tier has a different trust weight.
- **Confidence classification vocabulary** — `VERIFIED` (multiple sources) / `SUPPORTED` (single reliable) / `INFERRED` (logical deduction) / `UNVERIFIED` (needs confirmation). Every claim labeled.
- **Fact regression tests in bash** — 249 `grep -qiE` assertions (at `fb07fa8`) that claims still exist in the output doc. `check_present` / `check_absent` helpers. Zero dependencies. Catches regressions when data is refreshed.
- **Content-exclusion tests** — 12 tests ensure private interview content (salary, Glassdoor, mock questions, interviewer strategies) never leaks into the public-facing strategic analysis. `check_absent "description" "pattern" "$FILE"`.
- **Cross-model adversarial review** — Codex CLI (GPT-5.4 xhigh) independently reviews Opus 4.6's work. Self-review gave A, external gave D on the same doc. **Different model = different blind spots.**
- **The pushback round** — challenging flawed methodology mid-review found better issues than the initial review. Cross-model review is a dialogue, not one-shot.
- **Multi-document generator from single codebase** — one Python script, config dict per document, `sys.argv` selects which to build. Same CSS/JS, different content/nav/footer. Prevented drift between deliverables.
- **FIXABLE vs DATA CEILING deduction classification** — plateau detection to stop wasting iterations when remaining findings require external data we don't have.
- **"What This Means for the Interview" annotation** — every research finding tied back to actionable use. Raw data isn't a deliverable; the interpretation is.

### Key files to mine

- `states-project-research/CLAUDE.md` — source hierarchy, confidence vocabulary, review protocol
- `states-project-research/scripts/regression_test.sh` — the 249-assertion bash suite (at `fb07fa8`)
- `states-project-research/scripts/generate_pdf.py` — multi-deliverable renderer
- `states-project-research/.claude/skills/mock-interview/` — reusable skill pattern (generalizable to any prep-for-conversation use case)

---

## 3. tucson-investigation — Shannon Prouty's 2016 Hyundai Tucson

**Repo:** `~/tucson-investigation/` (private)
**Domain:** single-car automotive diagnostic research + dealer audit
**Lifecycle:** SDLC + ADLC (not a Research SDLC — the case evolved into an audit frame once the invoice landed)
**Scale at extraction** (pinned to `46cb786`, 2026-04-23): 36 commits on master (the v3.1 line is a subset), 111 pytest-collected tests (47 persona + 63 build-pipeline + 1 rulebook-drift), B+ composite audit grade on the paid stack, 9-round Codex xhigh review loop on the invoice audit.

### What it proved

- **Evidence class taxonomy** — `DIRECT` / `SUPPORTED` / `INFERRED` / `GAP` on every claim. Four classes, not VERIFIED/SUPPORTED/INFERRED/UNVERIFIED — the fourth class is explicit *"no source located"* rather than *"needs confirmation"*, which maps better to investigation work where some facts are structurally unknowable.
- **Stakeholder persona survival tests** — deliverables must pass Playwright-rendered HTML assertions from 4 personas (dad-reader, indie mechanic, dealer-side, skeptical reader). Different from unit tests; tests the finished artifact, not the input.
- **Methodology leak gate (L5)** — *"Codex", "ADLC", "xhigh", "cross-review", "L[0-9]{2,}"* must never appear in dad-facing deliverables (one content-anchored exception for a deliberate disclosure section). Automated on every pytest run.
- **AI slop gate (L12)** — automated banned-phrase scan on every test run (*"smoking gun", "game-changer", "deep dive", "delve"*, etc.). Zero hits or the test fails.
- **6-status canonical vocabulary** — `fair / above-market / below-market / not-on-schedule / not-applicable / not-verifiable` on every line item in the invoice audit. Prevents status drift.
- **The ratchet rule (L4, L17)** — every defect found becomes a permanent check. Evidence ledger is append-only (`evidence/MANIFEST.sha256`). L-codes only grow.
- **Freshness gate** — `md.mtime <= html.mtime <= pdf.mtime` across all deliverables. Catches "I edited the markdown but forgot to regenerate" at test time, not review time.
- **9-round cross-model review loop with xhigh** — Codex GPT-5.4 at maximum reasoning effort, 24 findings resolved across 9 rounds on one invoice audit. Produced the B+ composite grade.
- **Gate status doc as compass** — a single `.reviews/gate_status_YYYY-MM-DD.md` file tracks 17 gates with confidence percentages. Readable at a glance; drives the next action.

### Key files to mine

- `tucson-investigation/ADLC.md` — L1–L15 rulebook
- `tucson-investigation/SDLC_ADLC.md` — interop pattern (code lifecycle × audit lifecycle)
- `tucson-investigation/.claude/skills/adlc/SKILL.md` — invocable audit skill
- `tucson-investigation/.reviews/invoice_audit_2026-04-14.md` — full 9-round cross-model audit
- `tucson-investigation/.reviews/gate_status_2026-04-16.md` — 17-gate compass doc
- `tucson-investigation/tests/test_personas.py` — persona regression tests
- `tucson-investigation/tests/test_build_pipeline.py` — freshness gate tests

---

## Shared Patterns (Converged Independently)

These patterns showed up in all three repos without coordination. That convergence is what qualified RDLC for extraction.

| Pattern | anticheat | states-project | tucson |
|---------|-----------|----------------|--------|
| Evidence-quality labels on every source (axis 1 of 2 — see Divergences) | GRADE: Very Low / Low / Moderate / High | — (implicit via source hierarchy) | — (implicit via document class) |
| Claim-confidence labels on every assertion (axis 2 of 2 — see Divergences) | — (focuses on evidence quality, not claim confidence) | VERIFIED / SUPPORTED / INFERRED / UNVERIFIED | DIRECT / SUPPORTED / INFERRED / GAP |
| Cross-model review with a second model | Codex certification loop | Codex adversarial review | Codex xhigh 9-round loop |
| Fact regression tests (counting method varies — see each case study) | pytest-collected, HTTP-response asserts | bash `grep -qiE` asserts | pytest-collected, Playwright-rendered-HTML asserts |
| AI slop gate as a formal step | Slop patterns in review | Slop scan required | Automated L12 gate |
| Multi-audience deliverables from one base | clinician/family/litigation pages | interview/analysis/guide docs | cheatsheet/timeline/report |
| Ratchet rule (defect → permanent check) | Stale pattern families | Regression added per fix | L-codes monotonic |
| Pre-flight self-review before handoff | Required | Implicit via test suite | Automated via pytest |

## Divergences Worth Noting

- **The three vocabularies measure different things, not dialects of the same thing.** anticheat's GRADE labels (Very Low / Low / Moderate / High) measure *evidence quality* — how reliable is the underlying source (in vitro vs. clinical study vs. systematic review). tucson's DIRECT/SUPPORTED/INFERRED/GAP and states-project's VERIFIED/SUPPORTED/INFERRED/UNVERIFIED measure *claim confidence* — how well the claim is established given the sources. Both axes are load-bearing; neither subsumes the other. A mature RDLC standard should probably ask for both: an evidence-quality label (GRADE-style) AND a claim-confidence label (DIRECT/SUPPORTED/INFERRED/GAP-style). Treating them as three flavors of the same label, as earlier drafts of this page did, hides that split.
- **Among the two claim-confidence vocabs:** the fourth class differs. tucson uses `GAP` ("no source located — structurally unknowable"); states uses `UNVERIFIED` ("needs confirmation"). `GAP` is the right label for investigation work where some facts cannot be recovered; `UNVERIFIED` is the right label for research where the source exists but hasn't been checked yet. Pick per domain.
- **Tucson calls its domain lifecycle ADLC, not Research SDLC** — the project evolved from research into audit when the invoice arrived. This is a feature: the same loop supports both modes, just with different gate emphases.
- **Scale varies by ~10×** (anticheat is the biggest at 160 commits / 316 tests, tucson is the smallest at 36 commits / 111 tests). The patterns still held at every scale. That's strong evidence of generality.
- **Counting methodology differs per repo.** Pytest-collected counts include test-helper tests, parametrized cases, and meta-tests (e.g. tucson's `test_adlc_l12_slop_prose_is_subset_of_test_enforcement`). Bash `check_*` assertion counts are closer to "distinct claims guarded". HTTP-response regression counts are closer to "observable site behaviors guarded". Treat the axis as comparable, not the number.

---

## Contributions Inventory (artifact → source → wizard slot)

This table is the harvest map. When (or if) `claude-rdlc-wizard` graduates per the gates in `WIZARD_PLAN.md`, these are the artifacts to lift. Each row names **what to harvest**, **where it lives today**, **what it becomes in the wizard**, and **what shape change it needs first** (path-coupling is the #1 blocker — see `~/tucson-investigation/.claude/skills/README.md` § "Porting roadmap").

Mining rule: don't copy until the source artifact is `$ARGUMENTS`-driven and free of hardcoded paths. Path-coupled artifacts get **harvested in place** — read for pattern, but the wizard ships its own portable version.

### From `~/anticheat/`

| Artifact | Wizard slot | Port shape needed |
|---|---|---|
| `REVIEW_MATRIX.md` (A–G change classification) | `RDLC.md` R4 enforcement table + `cross-validate` skill routing | Lift table, generalize class labels (A–G are anticheat-domain); ship as preset in setup wizard |
| `REVIEW_FRAMEWORK.md` (audit types per class) | `RDLC.md` template § "Review Routing" | Restructure as per-class workflow; keep stale-pattern-family idea verbatim |
| `AGENT_REVIEW_LOOP.md` (standard sequence) | `cross-validate` + `certify` skill bodies | Direct port; replace anticheat-specific paths with `$ARGUMENTS` |
| `.claude/skills/sdlc/SKILL.md` (the `/sdlc` workflow skill) | `research` skill body — the day-to-day workflow skill | **Already `$ARGUMENTS`-driven and path-free** — closest portable shape in the inventory. Encodes the full loop: TodoWrite-first → confidence statement → DRY scan → prove-it gate → blast-radius check → TDD RED→GREEN → /code-review → cross-model with Codex → ratchet learnings. Lift the checklist structure verbatim; replace SDLC-specific terminology with research-domain terms (test → regression assertion, lint → slop scan, etc.). The PreToolUse TDD-CHECK hook firing on Edit/Write is the load-bearing enforcement piece — port the hook alongside the skill or the skill drifts. |
| `CONTENT_SDLC_AUTOMATION_PLAN.md` (canonical claim registry) | `RDLC.md` R1 enforcement notes | Pattern reference only — registry shape varies per project |
| Per-finding `response.json` (FIXED / DISPUTED / ACCEPTED) | `cross-validate` skill (mandatory output schema) | Lift verbatim — already general; wizard ships JSON schema + reviewer-side recheck protocol. **Schema gap discovered 2026-05-04 (anticheat `gaming-cert-may4-v1`)**: when round 1 mixes quick fixes with calibration work that needs a separate Codex *implementation* round, the three actions don't cleanly express "deferred to a separate review_id." The session extended the schema ad-hoc with `deferred_to: <new-review-id>` + `deferred_findings: [IDs...]`. The wizard should canonicalize a fourth action — **DEFERRED** — and ship the `deferred_to` field as part of the schema so the dialogue protocol covers split-fix cases without ad-hoc extension. |
| Audience-firewall pattern (`scripts/generate_pdfs.py` tab-stripping) | `audience-firewall-check.sh` hook + `audience-review` skill | Generalize: detect generator scripts, scan for audience-tagged content blocks |
| GRADE-aligned evidence labels (Very Low / Low / Moderate / High) | `EVIDENCE_STANDARDS.md` **medical preset** | Direct port; preset selector picks this when domain = medical/legal-evidence |
| Mission-context-required cross-model handoff | `cross-validate` skill (prompt template) | Lift the 5 fields verbatim: mission, success criteria, failure criteria, audience, stakes |
| Compound-level mechanism verification (DrugBank / ChEMBL / PubChem) | `verify-claim` skill (medical preset) | Pattern only — actual DB endpoints are domain-specific |
| Stale-pattern-family catalog (`REVIEW_FRAMEWORK.md` § "Recurring Stale-Pattern Families") + runnable checker `scripts/preflight.py` | `drift-scan` / `preflight` skill body + per-project pattern file | Catalog generalizes (each project ships its own `.rdlc-stale-patterns`); the checker is the load-bearing piece — multi-route HTTP fetcher with `--strict` mode for pre-release, exits non-zero on HIGH findings, JSON-able report. Port the script as the wizard's `preflight` skill body; project supplies the patterns. The May 4 GAMING-004 finding (paired-negative-regression rule) is a fresh datapoint that mechanical pattern checks must run *before* every Codex handoff, not after — anchor that ordering in the skill body. |
| MDLC trajectory backend (Phase A–C) | **Not in scope** for RDLC wizard | Defer to MDLC if/when extracted to `~/mdlc/`. Sibling pattern, not RDLC v1. |

### From `~/states-project-research/`

| Artifact | Wizard slot | Port shape needed |
|---|---|---|
| `scripts/regression_test.sh` (249 `check_present` / `check_absent` asserts) | `TESTING.md` template (bash flavor) | Wizard ships the helper functions verbatim; project earns its own assertions |
| Source-tier hierarchy (official > government > peer-reviewed > news > forum) | `SOURCE_HIERARCHY.md` template | Direct port as default; setup wizard lets project override per domain |
| VERIFIED / SUPPORTED / INFERRED / UNVERIFIED | `EVIDENCE_STANDARDS.md` **general/political preset** | Direct port; wizard's default if no domain-specific preset selected |
| `/mock-interview` skill | Optional add-on skill in wizard | Already path-light; rename + ship as `prep-conversation` if useful |
| `/tdd-fix` skill | `tdd-fix-prose` skill in wizard | **Blocked: hardcodes `output/interview_prep_document.md` + `scripts/regression_test.sh`.** Port plan in `~/tucson-investigation/.claude/skills/README.md` line 31-34: replace with `$ARGUMENTS` for both target doc + regression script |
| `/codex-review` skill | `codex-review` skill in wizard | **Blocked: hardcodes `output/interview_prep_document.md`.** Same port plan as tdd-fix |
| FIXABLE vs DATA CEILING classification | `research` skill workflow step (plateau detection) | Lift the decision tree verbatim; "stop iterating when remaining defects are external-data-bound" |
| Multi-document generator from single codebase | `ARCHITECTURE.md` template § "Multi-Deliverable" | Pattern reference; one Python script + config dict per document |
| 12 `check_absent` content-exclusion tests | `audience-firewall-check.sh` hook (proof of concept) | Pattern; wizard ships the hook, project writes its own per-deliverable assertions |
| Cross-model adversarial review proof (A self → D external) | `RDLC.md` R4 justification text + `feedback` skill onboarding | Lift the example as motivating story |

### From `~/tucson-investigation/`

| Artifact | Wizard slot | Port shape needed |
|---|---|---|
| `ADLC.md` (L1–L17 ratchet rulebook) | `RDLC.md` template structure | **Mine for shape, not content.** RDLC's R-codes are research-domain rules; tucson's L-codes are audit-domain. Same numbered-rule pattern, different rule set |
| `SDLC_ADLC.md` (dual-lifecycle interop) | Wizard-generated `SDLC_RDLC.md` (when both wizards installed) | Direct port; rename SDLC_ADLC → SDLC_RDLC, swap "audit" for "research" |
| `.claude/skills/adlc/SKILL.md` (invocable audit skill) | `research` skill body | Mine for the TaskCreate-first pattern + checklist structure |
| `.reviews/invoice_audit_2026-04-14.md` (9-round audit example) | Wizard docs § "Working Example" | Reference link only — keep in tucson; wizard cites it |
| `.reviews/gate_status_2026-04-16.md` (17-gate compass) | Wizard-generated `.reviews/gate_status_TEMPLATE.md` | Lift the table structure; project fills its own gates |
| `tests/test_personas.py` (persona regression tests) | `TESTING.md` template (pytest flavor) + `audience-review` skill | Generalize personas; wizard ships test harness, project defines its own personas |
| `tests/test_build_pipeline.py` § `TestFreshness` | `drift-gate.sh` hook | Lift the mtime comparison logic verbatim |
| `tests/test_personas.py::TestMethodologyLeakGate` | `slop-scan-on-edit.sh` hook | Lift the regex pattern as default; wizard ships allowlist mechanism (anchored on **content**, not line numbers — tucson lesson) |
| `METHODOLOGY_LEAK_PATTERN` regex | `slop-scan` skill default banlist | Direct port; project extends per its internal vocabulary |
| 6-status canonical vocab (PASS / PASS_WITH_NOTES / CONFIRMED / FAIL / CRITICAL_FAIL / INCONCLUSIVE) | `RDLC.md` template § "Review Status Vocabulary" | Direct port — already generic |
| DIRECT / SUPPORTED / INFERRED / GAP labels | `EVIDENCE_STANDARDS.md` **automotive/investigation preset** | Direct port; preset selector picks this when domain = consumer-investigation |
| Mandatory Codex invocation (`-m gpt-5.4 -c 'model_reasoning_effort="xhigh"' -s danger-full-access`) | `codex-review` skill body (mandatory section) | Lift verbatim; **never downgrade flags** — see `~/.claude/projects/-Users-stefanayala-tucson-investigation/memory/feedback_codex_reasoning_effort.md` |
| `python3 generate_report.py` triplet pattern | `ARCHITECTURE.md` template § "Single-Source → Triplet Output" | Pattern reference; xdlc Pattern #9 |
| L15 rulebook drift guard | `RDLC.md` R3 enforcement (every defect → ratchet test) | Lift the test pattern: assert ADLC.md banlist == test enforcement banlist |

### Anti-patterns each repo discovered (mine for **don't-do** rules)

| Anti-pattern | Source | Where it should land |
|---|---|---|
| Hardcoded test counts that drift ("227 tests" while actual is 254) | states + anticheat | `RDLC.md` R3 enforcement: counts must be dynamic or self-asserted |
| Citation-as-proof (PMID exists but doesn't support claim) | anticheat | `verify-claim` skill (require source-content match, not just URL existence) |
| Codex as first-pass QA (wastes review cycles) | anticheat | `cross-validate` skill (require preflight self-review first) |
| Allowlist-style test coverage (route-by-route, drift survives) | anticheat | `TESTING.md` template (default = scan all, opt-out only) |
| Generation script exits 0 on 404 (renders error body as PDF) | anticheat | `ARCHITECTURE.md` template (require HTTP status check in pipelines) |
| Shell variable interpolation in test patterns (`$95` becomes empty) | states | `TESTING.md` (bash flavor) — use word patterns, not dollar amounts |
| Hand-edited HTML drifting from CLI-generated `.md` | anticheat (Pattern #9 case study) | `drift-gate.sh` hook (load-bearing — ship by default) |
| Methodology terms leaking to reader-facing docs | tucson | `slop-scan` skill (project-internal banlist with content-anchored allowlist) |
| **Mechanical sitewide regex pass without paired negative-regression test** (anticheat `gaming-cert-may4-v1`, GAMING-004) — a color-rollout migration regex that matched any `#`-prefixed 6-7-char hex run silently mangled `IceC209#5794212` → `IceC209var(--accent-green)2` and `&#127920;` → `&var(--accent-green);`. Survived 20+ commits and the v8 cert because every existing regression test asserted *positive* content (page must say X) but none asserted *negative* invariants on the rewrite output (page must NOT say `var(--accent-…)` outside `<style>`). Caught on Codex first-pass cert two months later. | anticheat (May 4, 2026) | `RDLC.md` R3 enforcement: every mechanical sitewide rewrite must ship a paired negative-regression test *before* the rewrite runs. **Strengthens the existing "paired-negative-regression rule"** (anticheat `REVIEW_FRAMEWORK.md`, Apr 24) with a fresh dated example — the original rule covered cross-page contradictions (page-says-X, sibling-page-says-not-X); this case extends it to whole-class regex transforms (transform-must-not-leak-its-own-token-into-output). Wizard should ship the meta-rule: any `find/replace` or `sed -i` script gets a CI-style paired-negative test in the same change. |

---

## How to Contribute

This repo is the dump ground for RDLC patterns extracted from any research-lifecycle project:

- **From a case study repo:** add a section here with what your project proved. Include a link back to the repo's in-tree rulebook (`CLAUDE.md`, `ADLC.md`, `SKILL.md`, etc.). Keep the section self-contained — future readers should be able to mine it without opening the source repo.
- **From a pattern doc:** update `README.md` with the new pattern. If it conflicts with an existing pattern, flag the conflict rather than overwrite.
- **From an anti-pattern:** add it to the "Anti-Patterns Discovered" subsection of the relevant case study. Anti-patterns are as valuable as patterns.
- **From a portable artifact:** add a row to the **Contributions Inventory** above so the wizard build (when it happens) knows where to look.

Not yet installed: a `claude-rdlc-wizard` npm package (naming mirrors `claude-sdlc-wizard` per xdlc `d74d7cb`) or an `/rdlc` invocable skill. Those are future work — see `WIZARD_PLAN.md` for the implementation-ready plan and the four build gates that must hold first. Skills-first rule from xdlc: don't build the wizard until a new RDLC case study uses the patterns already here.
