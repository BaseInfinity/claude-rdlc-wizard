---
name: rdlc
description: Full RDLC workflow for research projects — gathering evidence, classifying confidence, cross-model review, audience-firewalled deliverables, fact regression tests. Use this skill when researching, fact-checking, drafting prose for external audiences, refreshing data, or shipping research deliverables.
argument-hint: [task description]
effort: high
---
# RDLC Skill — Full Research Workflow

## Task
$ARGUMENTS

Operational checklist. Full protocol lives in `RDLC.md` (consumer canonical) — read it for project-specific source hierarchy and confidence vocabulary.

**If the user requests /rdlc, ALWAYS run the full workflow — even for mechanical tasks.** Never silently skip; if overkill, say so and ask.

## Full RDLC Checklist

Your FIRST action must be a TodoWrite covering every phase below. Compact form (omit `activeForm` to use the subject as the spinner label):

```
TodoWrite([
  // PLAN
  { content: "Read RDLC.md — confirm source hierarchy, confidence vocab, slop list", status: "in_progress" },
  { content: "Read existing research files in scope — what's already known", status: "pending" },
  { content: "Define the claim or hypothesis under investigation", status: "pending" },
  { content: "Identify deliverable(s) and audience(s) — public, private, internal", status: "pending" },
  { content: "Source-tier check: which tiers can answer this? Primary databases first", status: "pending" },
  { content: "Present approach + STATE CONFIDENCE LEVEL", status: "pending" },
  // VERIFY
  { content: "Gather evidence from highest-tier sources first", status: "pending" },
  { content: "Cross-validate: ≥2 sources for VERIFIED, 1 reliable for SUPPORTED", status: "pending" },
  { content: "Label every claim VERIFIED / SUPPORTED / INFERRED / UNVERIFIED", status: "pending" },
  { content: "Source-at-first-mention; subsequent references inherit", status: "pending" },
  { content: "Update research/ files; add 'What This Means for [audience]' annotation", status: "pending" },
  // REVIEW
  { content: "Self-review: read back every claim, verify confidence label matches evidence", status: "pending" },
  { content: "Slop scan: bash scripts/slop_scan.sh — zero hits required", status: "pending" },
  { content: "Audience-firewall: confirm per-deliverable boundaries hold", status: "pending" },
  { content: "Pre-flight self-review document at .reviews/preflight-{id}.md", status: "pending" },
  { content: "Cross-model review (Codex xhigh) with mission-first handoff (if high-stakes)", status: "pending" },
  { content: "Dialogue loop until CERTIFIED (2 rounds sweet spot, 3 max)", status: "pending" },
  // SHIP
  { content: "Regenerate deliverables: python3 scripts/generate_deliverable.py", status: "pending" },
  { content: "Run fact regression suite: bash scripts/regression_test.sh — all pass", status: "pending" },
  { content: "Verify HTML/PDF rendering matches source — no stale builds", status: "pending" },
  { content: "Commit with conventional message", status: "pending" },
  // IMPROVE
  { content: "Every defect found by review → permanent regression test (TDD-for-prose)", status: "pending" },
  { content: "Capture earned rules in RDLC.md 'Lessons Learned'", status: "pending" }
])
```

## RDLC Quality Checklist (Scoring Rubric)

| Criterion | Points | Critical? | What Counts |
|-----------|--------|-----------|-------------|
| task_tracking | 1 | | TodoWrite or TaskCreate first |
| confidence | 1 | | State HIGH/MEDIUM/LOW before proposing approach |
| source_tier_used | 2 | **YES** | Highest available tier per claim; no over-relying on tier 7-10 |
| confidence_labels | 2 | **YES** | Every claim has VERIFIED/SUPPORTED/INFERRED/UNVERIFIED |
| slop_scan_pass | 1 | | Zero hits on banned-phrase grep |
| self_review | 1 | **YES** | Read back claims, verify labels match evidence |
| cross_model_review | 1 | | Run for high-stakes; document why if skipped |
| audience_firewall | 1 | | Per-deliverable boundaries verified |
| regression_added | 1 | | Every fix gets a permanent assertion |

**Total: 10 points.** Critical miss on `source_tier_used`, `confidence_labels`, or `self_review` = process failure regardless of total score.

## TDD for Prose

The core RDLC discipline: every defect becomes a permanent regression check.

```
Defect found → Write failing assertion → Fix the prose → Assertion passes → Commit
```

Concrete example from states-project-research:

1. Codex review caught a fabrication: "Giannetto worked on Biden's foreign relations team."
2. **RED:** added `check_absent "No Biden/Giannetto claim" "giannetto.*biden" "$DOC"` — failed.
3. **GREEN:** rewrote to "Giannetto's prior employment is documented at [actual sources]; no association with Biden administration verified."
4. Re-ran the regression suite — assertion passed.
5. Assertion stays in the suite forever. Future regenerations cannot reintroduce the fabrication without breaking the suite.

The ratchet only turns forward.

## Confidence Check (REQUIRED)

State your confidence before presenting an approach:

| Level | Meaning | Action |
|-------|---------|--------|
| HIGH (90%+) | Sources verified, claim well-established | Proceed after approval |
| MEDIUM (60-89%) | Solid evidence, some uncertainty | Highlight uncertainties; offer to gather more |
| LOW (<60%) | Sources weak or contradictory | ASK USER — gather more evidence or escalate to cross-model review |
| FAILED 2x | Repeated pushback from review | STOP and ASK USER |
| CONFUSED | Can't reconcile sources | Codex; if still confused, STOP and describe |

Dynamic effort bumping: if confidence drops mid-task, run `/effort xhigh` immediately. Spinning at default after confidence drops wastes budget.

## Plan Mode

Use plan mode for: multi-source claims, contested facts, anything cross-model-reviewed, drafting deliverables for new audiences, refreshing data with API calls. **Skip plan approval** when: trivial fix to a single claim with HIGH confidence, fixing a typo, removing a slop phrase. When in doubt, wait.

## Source Discipline

**Source-at-first-mention.** First time a claim references a source in a research file, cite it inline. Subsequent references in the same file inherit. New file = new first-mention required.

**Tier discipline.** When writing a claim, ask: what's the highest tier that can verify this? If a tier 1-2 source exists (primary database, government record), use it. Don't link to a news article *about* a primary source when the primary source is queryable.

**Anti-pattern: citation as proof.** A PMID existing does not mean it supports your specific claim. Read the abstract; verify the mechanism matches. Anticheat caught a months-long error where creatine was called a GABA-A agonist because nobody read the cited paper — the paper actually showed creatine *failed* to activate GABA-A.

## Confidence Labels — Worked Examples

**VERIFIED:**
> Giannetto serves as Senior Director of Lawmaker Engagement at The States Project. *(VERIFIED: TSP staff page [URL], LinkedIn [URL], TheOrg profile [URL] — three independent sources)*

**SUPPORTED:**
> The States Project enacted 187 policies in 2024. *(SUPPORTED: TSP policy library API [URL], single authoritative source)*

**INFERRED:**
> Giannetto is the probable hiring manager for the Lawmaker Engagement role. *(INFERRED at 70% confidence: title alignment + reporting structure shown in TheOrg + posting language matches her past hires; no direct confirmation)*

**UNVERIFIED:**
> The role's salary range is reported as $111,679–$117,262. *(UNVERIFIED: Glassdoor 4 self-reports — needs primary source)*

The label is part of the claim, not a footnote. It travels with the prose.

## AI Slop Gate

Run before every commit:

```bash
bash scripts/slop_scan.sh
```

Zero hits = pass. Any hit = review and rewrite.

**Allowlist for legitimate domain terms:** add proper nouns (mission pillar names, direct quotes) to `.rdlc/slop-allowlist.txt`, one per line. The scan excludes those.

**Cross-model slop scan.** Different models have different blind spots for their own generated language. The primary model may pass content the cross-model reviewer still flags as slop (proven in the tucson case study). For high-stakes deliverables, run the slop scan on the second model's output of the first model's draft.

## Audience Firewall

When the same research feeds multiple deliverables, each deliverable has its own audience boundary. The check belongs in the *generator*, not just the source pages.

Pattern (from states-project-research):

```python
# In generate_deliverable.py
DELIVERABLE_CONFIGS = {
    "private_interview_prep": {
        "audience": "internal",
        "include_sections": "all",
        "forbidden_patterns": [],
    },
    "public_strategic_analysis": {
        "audience": "external",
        "include_sections": ["org", "strategy", "competitive_landscape"],
        "forbidden_patterns": [
            "mock interview",
            "salary range",
            "Glassdoor",
            "interviewer strategy",
        ],
    },
}
```

Regression assertions that the public deliverable does NOT contain forbidden content:

```bash
check_absent "No salary in public deliverable" "111,679|117,262|salary range" "output/public_strategic_analysis.html"
```

Same enforcement applied at the generator AND the regression suite. Two layers because PDFs get forwarded without their context.

## Cross-Model Review

**When to run:** high-stakes deliverables (published research, legally adjacent, tone-sensitive — medical, family, attorney-facing).
**When to skip:** internal notes, brainstorming, drafts that won't ship.

Full protocol:

### Step 0: Preflight Self-Review

`.reviews/preflight-{review_id}.md` documents what you already checked: slop scan zero hits, all confidence labels present, audience firewall verified, regression suite green, specific concerns checked. Reduces reviewer findings to 0-1 per round.

### Step 1: Mission-First Handoff

`.reviews/handoff.json`:
```jsonc
{
  "review_id": "interview-prep-001",
  "status": "PENDING_REVIEW",
  "round": 1,
  "mission": "Liz interviews Tuesday for the Lawmaker Engagement role at TSP. The doc is the prep — confidence-blind to the actual conversation. 2-3 sentences.",
  "success": "She walks in knowing the org, the role, the people, and how her background fits — without needing to memorize anything.",
  "failure": "She quotes a fabricated stat in the interview because we missed it.",
  "audience": "Liz, PhD scientist, 14 years AAAS Policy work. Skeptical, time-bounded, cross-reads aggressively.",
  "stakes": "She gets the job or she doesn't. Wrong fact in our doc = wrong fact in her answer = she doesn't get the job.",
  "files_changed": ["output/interview_prep_document.md"],
  "fixes_applied": [],
  "previous_score": null,
  "verification_checklist": [
    "(a) Verify Giannetto's title against TSP staff page and LinkedIn",
    "(b) Verify policy enactment count against TSP policy library API",
    "(c) Slop scan zero hits",
    "(d) Confidence label on every claim"
  ],
  "review_instructions": "Adversarial. Assume claims are fabricated until proven. Cite file:line for every finding.",
  "preflight_path": ".reviews/preflight-interview-prep-001.md"
}
```

`mission/success/failure` give context. Without them: generic "looks good."

### Step 2: Run the Reviewer

```bash
codex exec -c 'model_reasoning_effort="xhigh"' -s danger-full-access \
  -o .reviews/latest-review.md \
  "Independent research reviewer. Read .reviews/handoff.json for context. \
   Verify each checklist item with evidence (URL, file:line, primary source). \
   Each finding: ID, severity (P0/P1/P2), evidence, fix condition. \
   End with: score (1-10), CERTIFIED or NOT CERTIFIED."
```

Always `xhigh`. Lower settings miss subtle errors.

**Sandbox note:** Codex's Rust binary needs `SCDynamicStore`; Claude Code's sandbox blocks this. Use `dangerouslyDisableSandbox: true` from CC. Codex has its own sandbox via `-s danger-full-access`.

CERTIFIED → ship. NOT CERTIFIED → dialogue loop.

### Step 3: Dialogue Loop

Per-finding response in `.reviews/response.json`:
```json
{"finding": "1", "action": "FIXED|DISPUTED|ACCEPTED", "summary": "..."}
```

Update `handoff.json`: increment `round`, status `PENDING_RECHECK`, add `fixes_applied`.

Recheck prompt:
> TARGETED RECHECK. For each finding: FIXED → verify fix condition. DISPUTED → ACCEPT if sound, REJECT with reasoning. ACCEPTED → verify applied. Do NOT raise new findings unless P0. End with score, CERTIFIED or NOT CERTIFIED.

**Convergence:** 2 rounds is the sweet spot, 3 max. After 3 still NOT CERTIFIED → escalate. Probably the premise is wrong, not the details.

**Anti-patterns:** "find at least N problems," "review this," 1-10 without criteria, letting reviewer see author's reasoning (anchoring).

### Audience-as-Reviewer Variant

For tone-sensitive deliverables, prompt the reviewer to adopt the audience's mindset:

> If you were [audience] reading this, when do you stop reading? Cite the line. What's the moment trust breaks?

This unlocks failure modes document-level review never finds. Tested on the anticheat /carlos page — went from generic "this section is too long" to specific "this line would make Carlos think the family is monitoring him."

Full protocol with rationale: `~/xdlc/docs/cross-model-review.md`.

## Refresh Data

Research data goes stale. Run before any deliverable ship:

1. Check organizational APIs (TSP policy library, FDA recall lists, FEC filings) for updated counts
2. Check legislative status of any bills mentioned
3. Verify employee titles (LinkedIn, TheOrg) — people move
4. Check job postings still live (Lever, Greenhouse, Workday)
5. Update timestamps in research files; flag claims older than 90 days for re-verification
6. Run regression suite — anything that was VERIFIED but now lacks sources gets demoted to UNVERIFIED

## Multi-Document Generators

When one research base feeds multiple deliverables: ONE script, config dict per deliverable, `sys.argv` selects which.

Pattern (states-project-research style):

```python
DELIVERABLE_CONFIGS = {
    "interview_prep": {...},
    "strategic_analysis": {...},
    "onboarding_guide": {...},
}

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "all"
    if target == "all":
        for name in DELIVERABLE_CONFIGS:
            generate(name)
    else:
        generate(target)
```

Same CSS, same nav, same source markdown. Different content/footer/forbidden-patterns per audience. Prevents drift between deliverables.

## Plateau Detection (FIXABLE vs DATA CEILING)

After ~3 review rounds, classify remaining deductions:

- **FIXABLE:** the source exists; we just need to use it. Action: fix.
- **DATA CEILING:** the source doesn't exist or isn't queryable in our tier set. Action: lower the claim's confidence, attribute, or cut.

Don't burn rounds 4–10 trying to fix DATA CEILING items. The plateau is the data, not the process.

## Scope, DRY, Patterns

- **Scope guard.** Only changes related to the task. Notice something else → NOTE in summary, don't fix unless asked.
- **DRY for prose.** Same fact appearing in 5 deliverables = 5 places to update when it changes. Centralize in research files; deliverables compose from research, not from each other.
- **DELETE legacy claims.** When a claim is corrected, delete the old wording everywhere — don't leave "previously thought" notes. They become stale-pattern magnets.

## Article Discovery (Optional)

When a research base accumulates, scan for publishable article angles:

1. Read all research/* files
2. Identify standalone narratives — claims that don't depend on the deliverable's full context
3. Group by theme
4. Each angle = a candidate publishable piece

Anticheat ran this in March 2026 and produced 48 standalone article angles from 96 research files. Pattern is reusable — formalize as `/article-discovery` skill in v0.5.

## Debugging Workflow

Reproduce → Isolate → Root Cause → Fix → Regression Test.

For research defects:
1. **Reproduce:** find the file:line where the wrong claim lives
2. **Isolate:** is this a single-source error, or has it propagated across deliverables?
3. **Root Cause:** what was the original source, and where did interpretation go wrong? Often: secondary source (news article) misquoted a primary source (paper); we copied the secondary.
4. **Fix:** rewrite at all sites
5. **Regression Test:** add `check_absent` for the wrong claim, `check_present` for the right one

2 failed attempts → STOP and ASK USER.

## Release Planning (When the Task Ships a Deliverable)

For deliverable releases (HTML/PDF for external audiences):

1. Refresh data (above)
2. Run regression suite — must be green
3. Slop scan — zero hits
4. Cross-model review with mission-first handoff
5. Audience-firewall verified per deliverable
6. Generate all deliverables: `python3 scripts/generate_deliverable.py`
7. Spot-check rendering (HTML in browser, PDF in viewer)
8. Commit
9. Distribute (HTML email with proper formatting; PDFs render in Apple Mail/Outlook differently — verify)

## After Session (Capture Learnings)

| Insight | Destination |
|---------|-------------|
| Source quirk (API rate limit, format change) | `RDLC.md` "Lessons Learned" |
| Confidence-label edge case | `RDLC.md` "Confidence Vocabulary" |
| Slop pattern not yet in banned list | `RDLC.md` "AI Slop Gate" — add to project allowlist or banned list |
| Audience-firewall miss | `RDLC.md` "Audience Firewall" + new regression assertion |
| Project context (deadline, stakeholder priority) | `CLAUDE.md` |

## Memory Audit Protocol

Per-user memory at `~/.claude/projects/<proj>/memory/` accumulates private learnings. Some are portable lessons worth promoting to wizard docs.

**When to run:** end-of-deliverable, after debugging-heavy sessions, on explicit "audit my memory" request.

**Rule-based denylist:**
- `type: user` → keep (user identity, preferences — never promote)
- `type: reference` → keep (external pointers, private by default)
- `type: project` → manual review (mixed state + portable lesson)
- `type: feedback` → manual review (mixed personal + portable rule)

**Destinations:** source quirks → `RDLC.md` "Lessons Learned." Audience patterns → `RDLC.md` "Audience Firewall." Process rules → `CLAUDE.md`.

**Tracking:** `promoted_to: <path>` in the memory file's frontmatter; later audits skip promoted entries.

**Human gate is MANDATORY.** Protocol produces diffs; user approves chunk-by-chunk.

## Post-Mortem: Process Failures Become Rules

```
Incident → Root Cause → New Rule → Test That Proves the Rule → Ship
```

Don't fix only the symptom. Add a gate so it can't happen again.

Example: states-project-research had `check_absent` for "Biden" because a fabrication had once put Giannetto on Biden's staff. The grep is permanent. Future regenerations cannot reintroduce it without breaking the suite.

## Context Management

- `/compact` between research and review (research artifacts preserved in summary)
- `/clear` between unrelated deliverables; after 2+ failed corrections (context polluted)
- After committing a deliverable, `/clear` before next task

---
**Full reference:** `RDLC.md` (consumer canonical with project-specific source tiers); upstream — `claude-rdlc-wizard`'s `PATTERNS.md` (cross-case-study patterns) and `CASE_STUDIES.md` (anticheat / states-project / tucson — what each proved); `~/xdlc/docs/cross-model-review.md` (mission-first prompt structure).
