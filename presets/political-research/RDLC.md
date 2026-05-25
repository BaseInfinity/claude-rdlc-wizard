<!-- RDLC Wizard Version: 0.6.0 -->
<!-- Setup Date: TBD -->
<!-- Completed Steps: -->
<!-- Domain: political-research -->
<!-- Preset Origin: states-project-research (interview prep, candidate vetting, policy analysis) -->

# RDLC Configuration — Political/Research Preset

This is the **political-research preset** of the RDLC canonical. Selected because the wizard detected political-research signals in this repo (e.g., FEC filings, Congressional records, H.R./S. bill references, 990 forms, `evidence/policy_documents/`, `fec/`, or `campaign/` directories).

If this was wrong, re-run `npx claude-rdlc-wizard init --preset general-research` (or another preset) to install a different canonical.

## What This Preset Adds Over the Generic RDLC

Political research and interview prep have lifecycle requirements that plain RDLC doesn't cover. From the `states-project-research` case study (43 commits, 257 bash assertions, Liz Chamberlain TSP interview prep):

- **Multi-tier private/public deliverable separation is the default, not an exception.** Interview prep produces both a doc *given to the candidate* (Guide_For_Liz) and *internal-only mock-interview material* with salary research, suspected weaknesses, and prep questions. A leak from internal-only into the public doc breaks the relationship with the interview subject. Generator-level enforcement, not source-page hygiene.
- **Primary-record citations beat aggregator citations.** OpenSecrets summarizes FEC data, but the FEC filing is the source of truth. 990 forms (IRS nonprofit returns) are tier-1 for nonprofit operations and compensation; the press article citing them is tier-4. Drift between aggregator and primary is the #1 fact-regression class.
- **Audience-as-reviewer is mandatory for interview prep.** "If you were the candidate reading this, when do you stop trusting me?" flushes out condescending framing that document-level review never catches. Applied at Round 3 of the Codex review loop.
- **Mock-interview content has a permanent firewall.** Mock questions, anticipated weaknesses, salary research, and "things to probe for" never appear in any deliverable handed to the subject. A regression check asserts this on every build.

## Wizard Version Tracking

| Property | Value |
|----------|-------|
| Wizard Version | 0.6.0 |
| Preset | political-research |
| Last Updated | 2026-05-25 |
| Claude Code Baseline | v2.1.111+ (required for Opus 4.7 / `opus[1m]`) |
| Recommended Model | `opus[1m]` for primary work, `gpt-5.5 xhigh` (Codex) for cross-model review |
| Recommended Effort | `max` for research drafting, `xhigh` for review (especially audience-as-reviewer rounds) |

## RDLC Enforcement (Political/Research Variant)

### 1. Source Discipline
- Every claim has a citation, URL, or primary-record reference (FEC filing ID, 990 form year, bill number, court docket)
- Primary records cited even when an aggregator (OpenSecrets, FollowTheMoney, GovTrack) has the same data — aggregators rephrase and drift
- Source-at-first-mention; subsequent references inherit

### 2. Confidence Classification
- Every claim labeled VERIFIED / SUPPORTED / INFERRED / UNVERIFIED
- VERIFIED requires ≥2 independent tier-1/2 sources OR 1 tier-1 with cross-check against the public record
- INFERRED claims about political behavior (motivation, alliance, intent) require an explicit reasoning chain — never infer-and-state

### 3. Cross-Model Review with Audience-as-Reviewer (Mandatory)
- Claude (primary author) drafts; Codex GPT-5.5 xhigh reviews
- Round 1: structural/factual review
- Round 2: tone, framing, condescension check ("if you were the subject, when do you stop trusting me?")
- Round 3: stakes-aware review with mission context ("this doc lands two days before the actual interview — what's the worst-case misread?")
- Convergence: 2 rounds sweet spot, 3 max; 4+ → escalate

### 4. AI Slop Gate
- Banned phrase list scanned via `grep -E` before commit
- Political-research-specific soft warns: "across the aisle", "common-sense", "stakeholder" (often political-vague), "the American people"
- Zero hits on tier-1 = pass

### 5. Audience-Firewall (Mandatory for This Preset)
- ANY deliverable handed to the interview subject / candidate / external counterparty MUST pass the firewall check
- Standard mapping below (extend per project)

### 6. Fact Regression Tests
- Every defect becomes a permanent regression check
- Special class: **leak regressions** — every time mock-interview content or salary research leaked into a subject-facing draft, the assertion becomes permanent
- The ratchet only turns forward — gates get stricter, never looser

## Hooks Installed

| Hook | Trigger | Purpose |
|------|---------|---------|
| `rdlc-prompt-check.sh` | Every prompt | RDLC baseline reminder |
| `rdlc-instructions-check.sh` | Session start | Validates RDLC.md exists; prompts setup if missing |
| `slop-scan-pretool.sh` | Before Write/Edit | Blocks AI slop additions |
| `confidence-required.sh` | Before Write/Edit on `research/`, `evidence/`, `policy_documents/` | Requires confidence label on new claims |
| `source-required.sh` | Before Write/Edit on research files | Requires source-at-first-mention |
| `audience-firewall.sh` | Before Write to `output/` | Blocks mock-interview/salary content from subject-facing deliverables |

## Skills Available

| Skill | Invocation | Purpose |
|-------|------------|---------|
| RDLC | `/rdlc` | Full research workflow guidance |
| Setup | `/setup-rdlc` | Confidence-driven project setup |
| Update | `/update-rdlc` | Smart update with drift detection |
| Feedback | `/feedback-rdlc` | Privacy-first contribution loop |

## Source Hierarchy (Political/Research — Primary Records on Top)

Tier 1 in this preset is **primary public records only**. OpenSecrets/FollowTheMoney/GovTrack drop to tier 3 — they're aggregators that rephrase primary data. Cite the FEC filing, not the summary of it.

| Tier | Source Type | Weight |
|------|-------------|--------|
| 1 | FEC filings, IRS 990 forms, Congressional records (Congress.gov), state campaign-finance disclosures | Highest — primary public record |
| 2 | Court filings (CourtListener, PACER, state court systems), federal/state regulatory orders | Highest — authoritative legal record |
| 3 | Aggregators with primary-record cross-reference (OpenSecrets, FollowTheMoney, GovTrack, ProPublica Nonprofit Explorer) | High — but drift-check against tier 1 |
| 4 | Established political news with editorial standards (NYT, WaPo, Politico, ProPublica originals) | High |
| 5 | Official organization sites (statesproject.org, party committees, campaign sites) | High for self-stated facts; treat advocacy with care |
| 6 | Professional profiles (LinkedIn, TheOrg, Crunchbase) | Moderate — operational, verify upstream |
| 7 | Issue-focused watchdog / advocacy sites (Citizens for Responsibility, OpenTheBooks, partisan trackers) | Moderate — note funding and ideological frame |
| 8 | Recorded interviews / podcasts with the subject (or with named principals) | Moderate (primary source for quotes) |
| 9 | Wikipedia, secondary political-bio aggregators (Ballotpedia for non-primary claims) | Low — verify upstream |
| 10 | Social media, anonymous posts, screenshots, transcribed verbal recollections | Lowest — attribute, do not assert |

## Confidence Vocabulary

| Label | Meaning | Required Evidence |
|-------|---------|-------------------|
| **VERIFIED** | Multiple independent sources confirm | ≥2 tier 1-5 sources OR 1 tier 1-2 with cross-check |
| **SUPPORTED** | Single reliable source, no contradictions | 1 tier 1-5 source |
| **INFERRED** | Logical deduction from verified premises | Reasoning chain documented; flag in text as "appears to" / "consistent with" |
| **UNVERIFIED** | Source exists but not yet checked, or conflicting sources | Note "needs confirmation" in text |

This preset uses **UNVERIFIED** as the fourth label (not GAP). Political research deals with public records — almost every fact has a discoverable source. If you can't find one, treat it as not-yet-checked rather than structurally unknowable.

## AI Slop Gate

Every content change must pass a slop scan before commit.

**Hard fail (rewrite immediately):**
deep dive, game-changer, cutting-edge, elevate, delve, tapestry, holistic, robust, paradigm, groundbreaking, streamline, empower, harness, unleash, unpack, pivotal, crucial, bigger picture, smoking gun, synergy, arguably, it's worth noting, at the end of the day, in today's world, needless to say

**Soft warn (political-research specific — check context):**
across the aisle, common-sense, the American people, stakeholder (when generic), navigate, facilitate, fundamental, principled, transparent (as filler), accountable (as filler), leverage (as verb)

**How to run:** `bash scripts/slop_scan.sh`

**Allowlist:** add direct quotes, mission-pillar names from organizations being researched, and proper nouns to `.rdlc/slop-allowlist.txt`.

## Audience Firewall (Standard Political/Research Mapping)

Interview-prep and candidate-vetting repos almost always produce both *external* (subject-facing) and *internal* (team-only) deliverables. The firewall is non-negotiable.

| Deliverable | Audience | Forbidden Content |
|-------------|----------|-------------------|
| `output/internal_*.md` / `output/mock_*.md` | Internal team only | (none — full content; this is the source of truth) |
| `output/subject_*.{html,pdf}` / `output/<NAME>_guide_*.{html,pdf}` | The interview subject / candidate | Salary research, mock-interview questions, anticipated weaknesses, "things to probe for", internal review notes, suspected motivations, opposition-research framing |
| `output/sponsor_*.{html,pdf}` / `output/funder_*.{html,pdf}` | External sponsor / funder / org leadership | Personal contact info, draft-stage editorial markers, internal disagreements between team members |
| `output/public_*.{html,pdf}` | Public-facing (blog post, press) | Everything in the two rows above, PLUS internal source rankings, unverified-but-strong-suspicion claims, anything labeled UNVERIFIED or INFERRED without explicit hedging |

The check belongs in the **generator** (Python/script that builds the deliverable). PDFs and HTML get forwarded without their source context — the boundary must hold at render time, not edit time.

## Cross-Model Review Protocol

For any published political-research deliverable:

1. **Pre-flight self-review.** Document every check at `.reviews/preflight-{review_id}.md`.
2. **Mission-first handoff.** `.reviews/handoff.json` with mission (2-3 sentences naming the outcome — e.g., "Liz reads this 48 hours before the TSP interview and walks in feeling prepared, not nervous"), success criteria, failure criteria, audience profile (who the subject is and what they care about), stakes, files_changed, verification_checklist.
3. **Run the reviewer.** Codex CLI at `model_reasoning_effort=xhigh`.
4. **Dialogue loop.** Round 1 factual/structural. Round 2 audience-as-reviewer ("if you were Liz, when do you stop trusting me?"). Round 3 stakes-aware ("what's the worst-case misread two days before the actual interview?"). 2 rounds sweet spot, 3 max, 4+ → escalate.
5. **Subject-facing deliverables always run rounds 2+3.** Internal-only deliverables can stop at round 1 unless they cite a primary-record claim.

Full protocol: `~/xdlc/docs/cross-model-review.md`.

## Fact Regression Tests

Every defect becomes a permanent check. Special focus: **leak regressions** — any time private content slipped into a subject-facing deliverable, the assertion is permanent.

```bash
# Source verification
check_present "FEC filing cited for campaign-finance claim" "FEC.*filing|fec\.gov" "$DOC"
check_present "990 form year cited for nonprofit-comp claim" "990.*2[0-9]{3}|IRS Form 990" "$DOC"

# Leak prevention
check_absent "No salary research in subject-facing doc" "salary range|comp range|expected salary|reported.*\\\$[0-9]+k" "$SUBJECT_DOC"
check_absent "No mock-interview questions in subject-facing doc" "mock question|likely to ask|probe for|anticipated weakness" "$SUBJECT_DOC"
check_absent "No internal review markers in any output doc" "TODO|FIXME|REVIEW:|XXX" "$DOC"

# Aggregator-vs-primary drift
check_absent_excl_review "No OpenSecrets-only citation without FEC cross-check" "OpenSecrets" "$DOC_WITHOUT_FEC"
```

Run: `bash scripts/regression_test.sh`

The test count grows monotonically. Test counts in docs go stale — verify dynamically or guard with a count assertion.

## Confidence Levels (For Tasks)

| Level | Meaning | Action |
|-------|---------|--------|
| HIGH (90%+) | Know exactly what to do | Proceed after approval |
| MEDIUM (60-89%) | Solid approach, some unknowns | Highlight uncertainties |
| LOW (<60%) | Not sure | ASK before proceeding |
| FAILED 2x | Something's wrong | STOP and ask for help |

## Configuration Files

```
.claude/
├── settings.json
├── hooks/
│   ├── _find-rdlc-root.sh
│   ├── rdlc-prompt-check.sh
│   ├── rdlc-instructions-check.sh
│   ├── slop-scan-pretool.sh
│   ├── confidence-required.sh
│   ├── source-required.sh
│   └── audience-firewall.sh
└── skills/
    ├── rdlc/SKILL.md
    ├── setup/SKILL.md
    ├── update/SKILL.md
    └── feedback/SKILL.md

scripts/
├── regression_test.sh        # Fact regression suite (leak regressions are permanent)
├── slop_scan.sh              # Banned-phrase grep (political-research soft warns)
└── generate_deliverable.py   # Multi-audience generator (subject/sponsor/internal/public)

research/                     # Topic-specific research files
evidence/
├── sources/                  # Raw source material with URLs
├── policy_documents/         # Bill text, regulatory filings, court docs
├── campaign_finance/         # FEC filings, 990 forms, state disclosures
└── public_record/            # Voting records, official statements
output/                       # Final deliverables (HTML, PDF) — audience-firewalled
.reviews/                     # Review artifacts (handoff.json, preflight-*.md)
.rdlc/
├── slop-allowlist.txt        # Project-specific exclusions
└── version                   # Wizard version for drift detection
```

## Lessons Learned

*(Empty at install. Populate as the project earns rules. States-project-originating lessons above are the inherited baseline; add project-specific ones below.)*
