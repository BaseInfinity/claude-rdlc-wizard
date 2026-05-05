# RDLC Patterns — Research Development Life Cycle

> **Consolidation note (2026-05-04):** This file was previously `~/rdlc/README.md` (the standalone pattern catalog repo). Per the GDLC retirement precedent (`~/gdlc/` retired into `claude-gdlc-wizard`), `~/rdlc/` has been retired and its content lives here in the wizard repo. The pattern catalog, case-study lessons, and deferred experiments now live alongside the installable wizard. See `EXTRACTION_NOTES.md` for the v0.1.0 build journal and `CASE_STUDIES.md` for proof-point cross-index. Historical references to `~/rdlc/` below describe the pre-consolidation state.

> Canonical home for RDLC research-lifecycle patterns, vocabulary, and case-study lessons. Extracted from `~/xdlc/docs/rdlc-patterns.md` on 2026-04-23 once the xdlc "two case studies → extract" threshold was met with three independent proof points: [anticheat](https://github.com/BaseInfinity/anticheat) (Content SDLC, medical/legal), [states-project-research](https://github.com/BaseInfinity/states-project-research) (Research SDLC, political/interview prep), and [tucson-investigation](https://github.com/BaseInfinity/tucson-investigation) (SDLC + ADLC, automotive diagnostics). See [CASE_STUDIES.md](CASE_STUDIES.md) for what each one proved.

Methodology and tooling for AI-assisted research projects. Same universal loop as SDLC (evidence > claims > confidence > validate > test > fix > iterate), applied to research domains.

## Writing Rule (Applies to ALL Output)

No AI slop. If it sounds like every ChatGPT response, rewrite it. Banned phrases: "deep dive", "game-changer", "cutting-edge", "elevate", "unpack", "delve", "tapestry", "holistic", "robust", "paradigm", "groundbreaking", "streamline", "empower", "harness", "unleash", "pivotal", "crucial", "bigger picture", "smoking gun", "in today's world", "it's worth noting", "at the end of the day". Use plain, direct language. This applies to all generated research, deliverables, and documentation.

## What This Is

This is the RDLC pattern catalog — the canonical home for the patterns, vocabulary, and case-study lessons that the lifecycle is built from. As of 2026-05-04 it lives in the `claude-rdlc-wizard` repo alongside the installable wizard (the standalone `~/rdlc/` repo was retired and consolidated here, mirroring the GDLC retirement pattern).

The installable wizard lives in this same repo at v0.1.0 (commit `396482e`, 2026-05-04). See [EXTRACTION_NOTES.md](EXTRACTION_NOTES.md) for the build journal.

Naming: the DLC ecosystem standardized on the `claude-*-wizard` prefix as of xdlc `d74d7cb`; older `agentic-*-wizard` references elsewhere in these docs are historical.

## Wizard Status (2026-05-04)

| Property | Value |
|----------|-------|
| Wizard repo | This repo — `claude-rdlc-wizard` ([BaseInfinity/claude-rdlc-wizard](https://github.com/BaseInfinity/claude-rdlc-wizard)) |
| Version | 0.1.1 (consolidation), 0.1.0 wizard core (commit `396482e`) |
| Distribution-ready | Yes — installable via `install.sh` or `npx` |
| Graduation status | Pre-graduation — awaiting first non-originating consumer |
| Skills shipped | `/rdlc`, `/setup-rdlc`, `/update-rdlc`, `/feedback-rdlc` |
| Hooks shipped | 6 + 1 helper — slop scan, confidence-required, source-required, audience-firewall, prompt-check, instructions-loaded-check |
| Templates shipped | 6 — RDLC.md, regression_test.sh, slop_scan.sh, generate_deliverable.py, slop-allowlist.txt, audience-firewall.conf |
| Tests | 3 suites, 28 assertions, all green |

See [`CHANGELOG.md`](CHANGELOG.md) for v0.1.1 consolidation details. The RDLC row in `~/xdlc/README.md` framework status table is updated to reflect this consolidation.

## Domain Vocabulary (vs SDLC)

| SDLC | RDLC |
|------|------|
| Write failing test | Form hypothesis / define claim |
| Implement feature | Gather evidence / research |
| Run tests (green) | Cross-validate sources |
| Lint / typecheck | Confidence scoring (VERIFIED / SUPPORTED / INFERRED / UNVERIFIED) |
| Regression tests | Fact regression tests (assertions on claims) |
| Code review | Cross-model review (adversarial validation) |
| TDD guard hooks | Source verification hooks |

## Proof Points

Three independent repos proved the same loop. Full cross-index in [CASE_STUDIES.md](CASE_STUDIES.md); short version here:

- **anticheat** — medical/legal evidence aggregation (Carlos Ayala case). GRADE-aligned evidence labels, certification queue, compound-level mechanism verification.
- **states-project-research** — political/interview-prep research (Liz Chamberlain, The States Project). Source-tier hierarchy, VERIFIED/SUPPORTED/INFERRED/UNVERIFIED labels, bash-based fact regression suite.
- **tucson-investigation** — automotive diagnostic + dealer audit (Shannon Prouty's 2016 Hyundai Tucson). DIRECT/SUPPORTED/INFERRED/GAP labels, stakeholder persona survival tests, L5/L12 automated gates, 9-round Codex xhigh loop.

All three converged on the same universal loop: evidence → claims → confidence labels → cross-validation → regression tests → iterate. Vocabulary differs by domain (see CASE_STUDIES.md § Divergences); the loop does not.

## v0 Scope (Historical — superseded 2026-05-04)

> **This section describes the original v0 scope as defined 2026-04-23. Two of the three "out of scope" rules were superseded when `~/claude-rdlc-wizard/` shipped at v0.1.0 on 2026-05-04. See [EXTRACTION_NOTES.md](EXTRACTION_NOTES.md) for the full record of what changed and why.**

**In scope (v0, 2026-04-23):**
- This `README.md` — seeded from `~/xdlc/docs/rdlc-patterns.md`, pattern index + lessons learned
- `CASE_STUDIES.md` — cross-index of the 3 proof-point repos, shared/divergent patterns table
- `EXTRACTION_NOTES.md` (added 2026-05-04) — what was learned during the wizard build

**Originally out of scope for v0:**
- ~~No canonical templates ported out of source repos.~~ **Superseded 2026-05-04:** templates were ported into `~/claude-rdlc-wizard/templates/` because a wizard's `setup` skill cannot reach into a private case-study repo at install time. Originating case-study repos remain authoritative for their own evolutions; the wizard ships generalized scaffolds.
- ~~No npm wizard, no `/rdlc` skill, no hooks.~~ **Superseded 2026-05-04:** wizard shipped at v0.1.0 with 4 skills + 6 hooks + 6 templates. Justification: GDLC's `claude-gdlc-wizard` v0.1.0 set the precedent — distribution-readiness ships first so a fourth consumer has something to install. Framework graduation remains a separate later milestone.
- No `docs/` subdir. Two files is enough — three now with EXTRACTION_NOTES.md. Structure grows when content justifies it.

**Graduation criteria for v1 (still in force):** a fourth (non-originating) case study consumes patterns from `~/claude-rdlc-wizard/` and produces an earned rule the originating three didn't. At that point the wizard tags v1.0.

## Hooks Installed (by `~/claude-rdlc-wizard/` v0.1.0)

- `slop-scan-pretool.sh` — banned-phrase grep on Write/Edit/MultiEdit (two-tier hard-fail/soft-warn with project allowlist)
- `confidence-required.sh` — claim-without-label gate on `research/`, `evidence/` paths
- `source-required.sh` — source-at-first-mention gate on research files
- `audience-firewall.sh` — per-deliverable forbidden-pattern gate on `output/` writes
- `rdlc-prompt-check.sh` — RDLC baseline reminder on every prompt
- `instructions-loaded-check.sh` — SessionStart RDLC.md presence check

All default to soft-warn. `RDLC_HOOKS_STRICT=1` opts into hard-block (exit 2).

Cross-model validation is documented in `~/claude-rdlc-wizard/skills/rdlc/SKILL.md` "Cross-Model Review" with the full mission-first handoff structure (mission + success + failure + audience + stakes), per [CASE_STUDIES.md § 1 (anticheat)](CASE_STUDIES.md#1-anticheat--carlos-ayala-medicallegal-case) and [§ 3 (tucson)](CASE_STUDIES.md#3-tucson-investigation--shannon-proutys-2016-hyundai-tucson). Not a hook — invoked via the `/rdlc` skill when a deliverable is high-stakes.

## Skills Provided (by `~/claude-rdlc-wizard/` v0.1.0)

- `/rdlc` — full research lifecycle workflow (Plan → Verify → Review → Ship → Improve)
- `/setup-rdlc` — confidence-driven setup wizard, scans for research signals
- `/update-rdlc` — drift reconciliation when wizard upgrades, preserves customizations
- `/feedback-rdlc` — privacy-first GitHub-issue contribution loop

The originally-planned `/verify-source`, `/refresh-data`, `/cross-validate`, `/audience-review` skills are **not standalone in v0.1.0** — their behavior is folded into the `/rdlc` skill's relevant sections. They graduate to standalone skills in v0.5+ if usage proves they need their own context (per skills-first rule).

## Relationship to Other Lifecycles

```
RDLC ──┐
       ├──> XDLC (meta-router, detects domain, picks lifecycle)
LDLC ──┘
       ^
     SDLC (exists: claude-sdlc-wizard)
```

Can be built in parallel with LDLC. XDLC depends on both existing first.

> **Open question**: Does LDLC collapse into an RDLC preset? Legal research is still research. The distinction: RDLC = "is this true?" → knowledge. LDLC = "is this acceptable?" → action (playbooks, redlines, signature routing). If LDLC turns out to be just a preset, merge it. Easier to merge than to split. Start simple.

---

## Lessons Learned from states-project-research

Reference repo: `~/states-project-research` — a complete RDLC cycle on a real project. Read its code, tests, and structure to extract patterns.

### What Worked

- **Source hierarchy with ranked tiers** — Official sites > government records > news > professional profiles > watchdog sites. Each tier has different trust weight. Defined in CLAUDE.md, enforced by convention.
- **Confidence classification on every claim** — VERIFIED (multiple sources), SUPPORTED (single reliable), INFERRED (logical deduction), UNVERIFIED (needs confirmation). This should be a hook, not just convention.
- **Fact regression tests in bash** — 249 `grep -qiE` assertions (at `fb07fa8`) that claims still exist in the output doc. Catches regressions when data is refreshed. `check_present` and `check_absent` helpers. Cheap, fast, zero dependencies. (Historical context: earlier drafts quoted 254 as the anti-pattern below describes — counts drift.)
- **Content-exclusion tests** — Critical for multi-audience deliverables. 12 tests ensuring private interview content (salary, Glassdoor, mock questions, interviewer strategies) never leaked into the public-facing analysis. Pattern: `check_absent "description" "pattern" "$FILE"`.
- **Cross-model adversarial review** — Codex CLI (GPT-5.4) independently reviewing Opus 4.6's work. Different model = different blind spots. The pushback round (challenging flawed methodology) found better issues than the initial review. This is a dialogue, not one-shot.
- **Multi-document generator from single codebase** — One Python script, config dict per document, `sys.argv` selects which to build. Same CSS/JS, different content/nav/footer. Prevented drift between deliverables.
- **"What This Means for the Interview" pattern** — Every research finding tied back to actionable use. RDLC equivalent: every finding needs a "So What?" annotation. Raw data isn't a deliverable.
- **Review rounds with scoring** — 24 review rounds, 200+ corrections. Each round had a grade. Plateau detection: classify remaining deductions as FIXABLE vs DATA CEILING to stop wasting iterations.

### What Should Become Hooks

- Source-at-first-mention enforcement (don't over-link, don't under-link)
- Confidence level required on every new claim added
- `check_absent` guard on audience-specific content (prevent leaks between deliverables)
- Stale data detection (flag claims with timestamps older than N days)

### What Should Become Skills

- `/verify-claim` — take a claim, find sources, assign confidence level
- `/refresh-data` — hit APIs/URLs mentioned in sources, flag what changed
- `/audience-split` — generate multiple deliverables from one research base with content firewalls
- `/mock-interview` — already exists in states-project-research as a skill, generalizable to any "prepare someone for a conversation" use case

### Anti-Patterns Discovered

- Shell variable interpolation in test patterns (`$95` becomes empty string with `set -euo pipefail`) — use word patterns, not dollar amounts
- BRE vs ERE regex in bash (`\|` vs `|`) — always use ERE with `grep -E`
- Cross-model review has diminishing returns on repackaged content — assess ROI before running, don't just run it because the checklist says to
- "227 tests" hardcoded in docs while actual count grew to 254 — test counts should be dynamic or verified by a test itself

---

## Lessons Learned from anticheat (Carlos Ayala Case)

Reference repo: `~/anticheat` — a medical/legal evidence system with 96 research files, 1,200+ citations, 248 regression tests, and Codex certification. The most battle-tested RDLC pattern in the portfolio.

### What Worked

- **Change classification system (A-G risk classes)** — Not all edits are equal. Class A (copy/layout) needs no review. Class C-F (medical/supplement/legal/mixed) needs full Codex certification. The REVIEW_MATRIX.md maps change type → required checks. RDLC equivalent: classify research edits by blast radius.
- **GRADE-aligned evidence labeling** — Every mechanism claim tagged with evidence quality: `[in vitro — GRADE: Very Low]`, `[clinical study — GRADE: Moderate]`, `[systematic review — GRADE: High]`. This should be a hook, not just convention. Prevents overclaiming.
- **Cross-page consistency scanning** — When a claim appears on multiple pages, changing it on one creates drift. Grep-based drift detection after every edit. RDLC: when the same fact appears in multiple deliverables, enforce sync.
- **Stale pattern families** — Recurring error patterns cataloged in REVIEW_FRAMEWORK.md. Instead of checking for individual errors, check for error *families*. Example: "PMC4874750 drift" = any time that PMID's findings get paraphrased differently across pages.
- **Compound-level mechanism verification** — Citation existence alone is insufficient. PMID can exist and still not support the specific claim. Must verify mechanism against primary databases (DrugBank, ChEMBL, PubChem). LESSON: Creatine was incorrectly called "GABA-A agonist" for months — PMID 36726215 showed creatine FAILED to activate GABA-A. Never skip source-level verification.
- **Pre-flight self-review before cross-model review** — Don't waste a Codex cycle on issues a self-check would catch. Write a preflight record documenting every check performed. Codex should find things you MISSED, not things you didn't bother to check. Consistently reduced Codex findings to 0-1 per pass.
- **Multi-audience pages from same research base** — Same 96 research docs serve: clinician pages (conservative, sourced), family pages (plain English), litigation pages (advocacy), and changelog (historical). Audience rules enforced per page. RDLC should formalize this: research is one thing, audience-specific deliverables are another.
- **Adversarial analysis as standard practice** — 8 alternative explanations tested, 6 eliminated, 1 possible, 1 insufficient. "Honest holes" section published alongside findings. Builds credibility. Every research project should try to destroy its own thesis.
- **Certification queue workflow** — Pages queue for certification. Each gets versioned review rounds (v1, v2, v3...). Artifact preserves the reviewer's findings. Status machine: IDLE → IN_REVIEW → CERTIFIED/REVIEWED/BLOCKED. Prevents duplicate reviews and lost state.
- **248 regression tests on served HTML** — pytest tests that hit the actual server and assert content. Not mocks — real HTTP requests. Every fixed error becomes a test. The test suite IS the source of truth for what should be on each page.
- **Plugin/MCP/skill ecosystem for verification** — DrugBank, ChEMBL, PubChem, FDA, PubMed, USPTO, EDGAR, CourtListener — each tool verifies claims at the PRIMARY SOURCE. Secondary sources drift. EDGAR would have caught a $5.89B mislabel on first pass instead of 3 Codex rounds. Always check if a tool exists before relying on web search.
- **Cross-model reviews need mission context, not just artifacts** — Sending "review this plan" to Codex gets generic structural feedback. Sending "THE MISSION: Stefan visiting brother in person, Carlos has anosognosia, if page feels like an intervention the trust channel closes permanently — now review this plan" gets feedback grounded in actual stakes. Every cross-model handoff should lead with: (1) the mission, (2) success criteria, (3) failure criteria, (4) audience profile, (5) stakes. LESSON: Round 1 without context gave 5 structural findings. Round 3 with full mission context gave specific, actionable feedback tied to the actual failure mode. The reviewer can't optimize for your goal if it doesn't know your goal.

### What Should Become Hooks

- GRADE label required on every new mechanism/evidence claim
- Cross-page drift scan after any content edit (grep-based)
- Stale pattern check against known error families
- Pre-flight self-review gate before cross-model handoff
- Compound/claim verification against primary database (not just citation check)
- Audience boundary enforcement (clinical language doesn't leak to family pages)
- Mission context required in every cross-model handoff prompt (success/failure/audience/stakes)

### What Should Become Skills

- `/verify-mechanism` — take a mechanism claim, check DrugBank/ChEMBL/PubChem, return evidence level
- `/drift-scan` — find all pages containing a claim, check for consistency
- `/certify` — full certification workflow: preflight → handoff → Codex review → pick up results
- `/article-discovery` — scan research files, identify standalone article angles, group by theme (this is what we just did manually — 48 articles from 96 research files)

### Anti-Patterns Discovered

- **Citation as proof** — A PMID existing does not mean it supports your specific claim. Must read the abstract and verify the mechanism matches. Creatine GABA-A error survived months because nobody checked the actual paper.
- **Treating Codex as first-pass QA** — Wastes review cycles and context. Do the same checks yourself first. Codex is a second pair of eyes, not a substitute for your own review.
- **Relying on secondary sources for verifiable facts** — SEC filings, patents, FDA actions are all queryable at the source. Web articles about these introduce telephone-game errors. Use EDGAR, USPTO, openFDA directly.
- **"5 products" hardcoded while actual count grew to 6, then 7** — Same as states-project-research's test count problem. Counts should be dynamic or guarded by regression tests.
- **Legacy fallback code** — When a claim is corrected, DELETE the old wording everywhere. Don't leave commented-out or "was previously" notes. They become stale pattern magnets.

### Article Discovery Pattern (March 31, 2026)

Ran systematic scan of all 96 research files + iMessage evidence + served pages + methodology docs. Produced **48 standalone public education article angles** across 14 categories — all based entirely on existing data, zero external dependencies. This process should be formalized as an RDLC skill: given a research knowledge base, what publishable articles can be generated?

Categories found: supplement safety (7), industry accountability (3), regulatory gaps (2), gaming (5), hospital/healthcare (2), fintech (1), AI psychosis (1), cross-cutting compound stories (7), behavioral/iMessage data (3), methodology (2), data journalism (3), consumer action (4), corporate accountability (4), deep data (3).

### PDF Deliverables Pipeline Lessons (April 2026)

Three PDF deliverables were generated for Carlos's medical team from existing HTML pages (`/physician-summary`, `/carlos`, `/supplements`). Took 3 full Codex certification rounds before shipping. Lessons:

- **Audience-firewall rules extend to deliverable generators, not just pages.** `/supplements` has a "Bottle Evidence" tab with manufacturer/legal claims — appropriate for the litigation audience that hits the site, inappropriate for the PCP reading a PDF. The fix was to exclude `tab-bottles` in the generator's headless Chromium script *before* printing. The page's audience isn't fixed — the *deliverable's* audience is. RDLC implication: when the same research feeds multiple deliverables, each deliverable needs its own audience boundary scan, and scripts that cut deliverables from pages need the same review rigor as the pages.
- **Stale-pattern tests cover the routes they know about — and miss everything else.** The parametrized `_CERTIFIED_ROUTES` list included `/physician-summary`, `/supplements`, `/carlos`, etc., but not `/` (homepage). A stale "near-identical" phrasing for PMC4874750 drifted onto the homepage and survived every test run. Codex caught it. Rule: route-level coverage should be *by default*, not opt-in. Anti-pattern: allowlist-style test coverage that grows by hand.
- **Generation scripts need HTTP status verification.** First version of the PDF generator exited 0 even when pages returned 404 — it happily rendered an error body as a PDF. Fixed by capturing `page.goto()` response and raising on non-200. Rule: any automation that shells out to a server must check status, not just "did the file get written."
- **Screenshot / verbal-transcription claims must be attributed, not stated as fact.** An "MRI" mentioned in a Dad-recounted hospital visit made it onto `/carlos` as a flat fact. Source was a screenshot transcription, unverified against actual records. Fix: either remove it, or attribute it ("Dad says no medical cause was found"). This is a specific instance of the broader rule that unverified claims need a GRADE tag or explicit attribution — never passed through as narration.
- **Three-round certification is the sweet spot for complex deliverables.** Round 1 surfaces 4-6 structural issues, Round 2 catches 1-2 items from the fix cascade (the fix introduced a new issue), Round 3 certifies. Going more rounds than that means the premise is wrong, not the details. Going fewer means the reviewer didn't see enough.
- **Mission context in the handoff is more load-bearing than the artifact itself.** Round 1 on this batch got a generic "structure/tone/GRADE-label" response. Round 3, with "mission: these PDFs may be the thing that keeps Carlos on meds long enough to not relapse — the PCP is skeptical" in the prompt, got specific, actionable findings tied to the real failure mode. The reviewer can't optimize for your outcome if it doesn't know your outcome.

---

## Lessons Learned from AI Slop Audit (March 31, 2026)

The states-project-research project ran a full content quality audit that surfaced patterns any RDLC needs to handle.

### AI Slop Gate Must Be a Formal Lifecycle Step

Not optional, not a suggestion — a gate. `grep -rniE` with a banned phrase list, hard-fail tier (rewrite immediately) and soft-warn tier (check context). Zero hits = pass. Any hit = review and rewrite before the deliverable ships. This caught 24 instances across 45+ files that human reviewers missed because the phrases "sounded fine."

The slop scan command is cheap (~1 second across an entire repo). No reason not to run it on every commit. Should become a PreToolUse hook or a pre-commit hook.

### Cross-Model Slop Detection Is Not Optional

Opus 4.6 found 17 instances. GPT-5.4 (Codex) found 7 more that Opus missed — including section headers like "Thought Leadership" and "Powerhouse" that Opus considered legitimate. Different models have different blind spots for their own generated language. **Two models scanning for slop > one model scanning twice.** This should be a standard RDLC gate: self-scan, then cross-model scan.

### Allowlist Proper Nouns in Slop Scans

"Empowering People over Special Interests" is TSP's actual mission pillar name. "Empower legislators to lead boldly" is a direct quote from a strategic plan. Both trigger the slop scan's "empower" rule. The scan needs a way to distinguish AI filler from legitimate domain vocabulary — either a per-project allowlist file or inline `<!-- slop-ok -->` markers. Without this, you waste time investigating false positives.

### Section Headers Multiply Slop Exposure

"Company Culture Deep Dive" as a heading gets repeated in the TOC, the nav bar, the URL fragment, and screen reader output. One slop phrase in a header has 4x the surface area of one in body text. Headers should get extra scrutiny — or a separate, stricter scan.

### Stakeholder Delivery Needs Formatting

Sending markdown as plain text email to Gmail renders literal `##` and `---`. Research deliverables sent to non-technical stakeholders need HTML formatting. This is a packaging concern: the RDLC should have a "deliver" step that handles format conversion for the target audience (HTML email, PDF attachment, web link, etc.).

### The Slop Audit Pattern (Reusable)

```
1. Define banned phrase list (hard-fail + soft-warn tiers)
2. grep scan all content files → list all hits
3. Classify each hit: SLOP (rewrite) / BORDERLINE (check context) / LEGITIMATE (domain term, direct quote)
4. Fix all SLOP instances
5. Cross-model review (different AI scans same files)
6. Fix additional findings
7. Re-run scan → zero hits = pass
8. Regenerate all deliverables from fixed source
9. Run regression tests → all green
```

This pattern applies to any lifecycle that produces written content — RDLC, LDLC, even SDLC (code comments, docs, READMEs).

---

## Deferred Experiments

### Deep Research vs DLC Stack Benchmark

> **Status:** parked 2026-04-15. Not scheduled. Run only after tucson v3.1 invoice reconciliation ships and no active audit pass is running. This is a benchmark, not a fire drill.

**The question:** does ChatGPT Deep Research close the gap on our SDLC + ADLC + Codex-xhigh + persona-tests + ratchet stack, or is it a draft generator that still needs the gates run over its output?

Deep Research is a single-shot agentic research tool. Our stack is a multi-loop lifecycle (tucson: 14 L-codes, 96 regression tests, cross-model review loop). They produce the same output shape — a sourced research deliverable for a non-expert reader — but the investment is very different. The comparison validates (or falsifies) whether the lifecycle overhead earns its keep.

**Test rig:**

Use `tucson-investigation/v3.1` as the shared baseline. It's graded B+, sourced, and the test suite is live. Give Deep Research a bounded prompt: *"Produce a mechanic-ready report on Shannon Prouty's 2016 Hyundai Tucson AC and door-latch failures. Every claim must cite a source. The reader is her dad, a non-engineer."* Feed it the same raw inputs we had (iMessage threads, NHTSA recall data, TSB PDFs, dealer invoice) or let it find its own. Save the output to `.reviews/deep_research_tucson_<YYYY-MM-DD>.md` plus rendered HTML.

Then run the full ADLC gate checklist (L1–L14) against Deep Research's output:

| Dimension | Our stack baseline (tucson v3.1) | How to grade Deep Research |
|-----------|----------------------------------|-----------------------------|
| Evidence grade per claim (DIRECT / REPRODUCED / POLICY / INFERRED / EXTERNAL / UNVERIFIED) | graded in `dads_cheatsheet.md` | manual pass, same taxonomy |
| Source discipline (L9) — every claim has a live link | 100% in v3.1 | curl every URL, count dead/missing |
| Methodology leak grep (L5) — `Codex\|ADLC\|xhigh\|L[0-9]{2,}\|as an AI\|based on my research` | 1 allowed exception (`dads_cheatsheet.md:210`) | run the same grep |
| AI slop gate (L12) — banned phrases | 0 hits | adapt `tests/test_personas.py::TestAllPersonas::test_no_ai_slop_phrases` |
| Stakeholder persona survival (L6) — Eric / Laura / indie mechanic | 40 tests pass | render output to HTML, run `tests/test_personas.py` against it |
| Confidence gate (L9 hedge language) — no claim stronger than evidence | hand-graded | manual pass, look for over-claims |
| Cross-model review (L8) — does another model catch its mistakes? | Codex xhigh finds defects | send Deep Research output to Codex xhigh, count findings per round |
| Cost ($ per run) | near-zero per round, bounded by round cap | OpenAI pricing × runs |
| Wall clock time | 10+ rounds over weeks for v3.1 | single run, ~30 min estimated |
| Reproducibility | deterministic (markdown → regen) | run Deep Research twice, diff outputs |
| Regression discipline | 96 tests, ratchet (every defect → new test) | can you bolt a regression test onto a Deep Research run at all? |
| Human override / ratchet | every defect becomes a permanent gate | structural — no persistent state between runs |

**Hypotheses to falsify:**

1. **Speed:** Deep Research is faster on the first pass. No L-codes to write, no rulebook to consult, no cross-review loop. *Expected TRUE.*
2. **Breadth:** Deep Research surfaces sources we never looked for. *Expected TRUE.*
3. **L5 methodology leak:** Deep Research fails the grep without hand-editing. Its default voice is *"As an AI, I searched for..."* — exactly what Eric cannot see. *Expected TRUE.*
4. **L12 AI slop:** Deep Research fails the banned-phrase gate without hand-editing. Slop vocabulary is in its training distribution. *Expected TRUE.*
5. **L6 persona tests:** Deep Research will not survive `tests/test_personas.py` without hand-editing. The tests were written by a human to catch specific past mistakes; Deep Research can't see those past failures. *Expected TRUE.*
6. **Ratchet:** You cannot bolt the ratchet onto Deep Research — each run is a fresh context, so there's no way to accumulate *"every defect becomes a permanent check."* *Expected STRUCTURALLY UNFIXABLE without external scaffolding.*

**Three possible outcomes:**

- **Additive** — Deep Research wins on speed + breadth AND passes the gates. Action: use it as the first-pass research engine, then run our lifecycle over its output.
- **Draft generator** — Deep Research wins on speed + breadth, fails the gates. Action: it's a draft source, not a deliverable. Our lifecycle stays as the grading and review layer. *(Most likely outcome.)*
- **Worse** — Deep Research loses on speed + breadth AND fails the gates. Action: validation that the lifecycle overhead is earning its keep.

**Run procedure when we pick it up:**

1. Confirm tucson v3.1 invoice reconciliation is shipped AND no active audit pass is running.
2. Pin the baseline: snapshot `dads_cheatsheet.md`, `car_report.md`, `.reviews/invoice_audit_2026-04-14.md` at the commit we're comparing against.
3. Run Deep Research with the prompt + attached raw evidence. Save the output verbatim to `tucson-investigation/.reviews/deep_research_tucson_<YYYY-MM-DD>.md`.
4. Render Deep Research's markdown to HTML using `generate_report.py` so the persona tests can run against it.
5. Run the full ADLC gate checklist (L1–L14) against the Deep Research output. Document every violation with the L-code.
6. Run Codex xhigh cross-review on both outputs. Save to `.reviews/codex_deep_research_compare_<date>.txt`.
7. Score both with the 6-status canonical vocabulary (L13) on every gate.
8. Write the outcome as a new RDLC pattern entry in this file — pick one of the three categories, state why, link the Codex artifacts.
9. Save lessons to the tucson + xdlc memory namespaces per the cross-pollination pattern.

**Why this matters:**

RDLC's premise is that the universal loop pays for itself because the domain-specific verification steps catch defects that single-shot agentic tools miss. If a single-shot tool closes the gap, the framework needs to absorb it (additive case). If it doesn't, the framework is validated. Either outcome is load-bearing for the RDLC extraction decision — which is why this comparison is worth preserving even though we're not running it yet.

**References:**

- `tucson-investigation/ADLC.md` — full L-code rulebook Deep Research will be graded against
- `tucson-investigation/.claude/skills/adlc/SKILL.md` — gate checklist and mandatory Codex invocation
- `tucson-investigation/tests/test_personas.py` — 40 stakeholder tests Deep Research must survive
- `tucson-investigation/.reviews/invoice_audit_2026-04-14.md` — v3.1 baseline
