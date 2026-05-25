<!-- RDLC Wizard Version: 0.6.0 -->
<!-- Setup Date: TBD -->
<!-- Completed Steps: -->
<!-- Domain: medical-legal -->
<!-- Preset Origin: anticheat (medical/legal evidence aggregation, GRADE-aligned) -->

# RDLC Configuration — Medical/Legal Preset

This is the **medical-legal preset** of the RDLC canonical. Selected because the wizard detected medical/legal research signals in this repo (e.g., PMID citations, DrugBank/ChEMBL/PubChem references, GRADE labels, `clinical/` or `evidence/team_profiles/` directories).

If this was wrong, re-run `npx claude-rdlc-wizard init --preset general-research` (or another preset) to install a different canonical.

## What This Preset Adds Over the Generic RDLC

Medical/legal research has lifecycle requirements that plain RDLC doesn't cover. From the `anticheat` case study (160 commits, 316 tests, Carlos Ayala medical evidence aggregation):

- **Two-axis confidence labeling.** Plain RDLC labels *claim confidence* (VERIFIED/SUPPORTED/INFERRED/UNVERIFIED). Medical/legal also requires *evidence quality* via GRADE (Very Low / Low / Moderate / High). A claim can be VERIFIED (multiple sources agree) but rest on GRADE: Very Low evidence (all sources cite the same in vitro study). Both labels are required on mechanism/efficacy claims.
- **Primary-database verification, not citation existence.** A PMID can exist and not support the specific claim. Mechanism claims must be verified against DrugBank, ChEMBL, PubChem, or openFDA directly — not via web articles about them. Originating lesson: creatine was incorrectly labeled "GABA-A agonist" for months; the PMID existed but actually documented that creatine *failed* to activate GABA-A.
- **Audience-firewall is mandatory.** A single-audience document can be unsafe for the patient even when correct for counsel. Clinician-safe deliverables strip litigation language; patient-facing deliverables strip manufacturer marketing claims. The generator enforces this at render time.
- **Provider-eligibility / certification status verification.** Operational facts (license numbers, board certifications, scope of practice) need a verification queue with re-check dates — they decay.

## Wizard Version Tracking

| Property | Value |
|----------|-------|
| Wizard Version | 0.6.0 |
| Preset | medical-legal |
| Last Updated | 2026-05-24 |
| Claude Code Baseline | v2.1.111+ (required for Opus 4.7 / `opus[1m]`) |
| Recommended Model | `opus[1m]` for primary work, `gpt-5.5 xhigh` (Codex) for cross-model review |
| Recommended Effort | `max` for research drafting, `xhigh` for review and verification |

## RDLC Enforcement (Medical/Legal Variant)

### 1. Source Discipline
- Every claim has a citation, URL, or primary-database ID (DrugBank / ChEMBL / PubChem CID / openFDA UNII / PMID)
- Sources ranked by tier (see "Source Hierarchy" below — tier 1 is primary databases only)
- Source-at-first-mention; subsequent references inherit

### 2. Two-Axis Claim Labeling — Confidence AND Evidence Quality

**Axis 1 (claim confidence):** VERIFIED / SUPPORTED / INFERRED / UNVERIFIED — how well the claim is established given the sources.

**Axis 2 (evidence quality, GRADE-aligned):** Very Low / Low / Moderate / High — how reliable the underlying source is.

Mechanism, efficacy, dosage, and contraindication claims **require both labels**. Operational claims (e.g., "Dr. X is board-certified") need only the confidence label plus a re-check date.

Format examples:
- `[mechanism — VERIFIED · GRADE: Moderate]` — multiple clinical studies cited; quality is moderate, not high (no systematic review yet)
- `[in vitro finding — SUPPORTED · GRADE: Very Low]` — one in vitro paper, no human data
- `[systematic review consensus — VERIFIED · GRADE: High]`

### 3. Cross-Model Review with Audience-as-Reviewer
- Claude (primary author) drafts; Codex GPT-5.5 xhigh reviews
- Mission-first prompt structure: mission, success, failure, audience, stakes
- For tone-sensitive deliverables (patient-facing, clinician-facing), use the audience-as-reviewer variant: *"If you were the patient/PCP, when do you stop reading?"*
- Convergence: 2 rounds is the sweet spot, 3 max; 4+ rounds is a signal to escalate to a human reviewer

### 4. AI Slop Gate
- Banned phrase list scanned via `grep -E` before commit
- Tier-1 hard fail; tier-2 soft warn (legitimate medical use of e.g. "comprehensive" is OK)
- Zero hits on tier-1 = pass

### 5. Audience-Firewall (Mandatory for This Preset)
- Multi-deliverable repos MUST enforce per-audience content boundaries
- Generator-level enforcement (not just source-page) — PDFs and HTML forward without context
- See "Audience Firewall" section below for the standard medical mapping

### 6. Fact Regression Tests
- Every defect becomes a permanent regression check (`check_present` / `check_absent`)
- The ratchet only turns forward — gates get stricter, never looser
- Mechanism-correction defects (creatine/GABA-A class) become permanent assertions

### 7. Certification / Provider-Eligibility Queue
- Operational facts about providers decay (license status, board cert, scope of practice)
- Maintain `.rdlc/certification-queue.md` with `(provider, fact, last_checked, recheck_date, source_url)`
- Pre-publish gate: any fact past its `recheck_date` blocks the deliverable

## Hooks Installed

| Hook | Trigger | Purpose |
|------|---------|---------|
| `rdlc-prompt-check.sh` | Every prompt | RDLC baseline reminder |
| `rdlc-instructions-check.sh` | Session start | Validates RDLC.md exists; prompts setup if missing |
| `slop-scan-pretool.sh` | Before Write/Edit | Blocks AI slop additions |
| `confidence-required.sh` | Before Write/Edit on `research/`, `evidence/`, `clinical/` | Requires confidence label on new claims |
| `source-required.sh` | Before Write/Edit on research files | Requires source-at-first-mention |
| `audience-firewall.sh` | Before Write to `output/` | Blocks audience-private content from public deliverables |

## Skills Available

| Skill | Invocation | Purpose |
|-------|------------|---------|
| RDLC | `/rdlc` | Full research workflow guidance |
| Setup | `/setup-rdlc` | Confidence-driven project setup |
| Update | `/update-rdlc` | Smart update with drift detection |
| Feedback | `/feedback-rdlc` | Privacy-first contribution loop |

## Source Hierarchy (Medical/Legal — Primary Databases on Top)

Tier 1 in this preset is **primary databases only**. PubMed papers move to tier 3 — they're peer-reviewed but the claim must be verifiable at the source database, not via the paper alone.

| Tier | Source Type | Weight |
|------|-------------|--------|
| 1 | Primary databases (DrugBank, ChEMBL, PubChem, openFDA, RxNorm, UNII) | Highest — authoritative for mechanism/identity/labeling |
| 2 | FDA actions, EMA decisions, CDC/WHO guidance, court filings, state medical-board records | Highest — authoritative for regulatory/legal status |
| 3 | Peer-reviewed papers (PubMed, PubMed Central, Cochrane reviews) | High — graded individually via GRADE axis |
| 4 | Clinical practice guidelines (specialty society consensus) | High |
| 5 | Established medical news (NEJM Journal Watch, MedPage Today with editorial review) | Moderate |
| 6 | Provider directories (NPI, state license lookup, board certification verification) | Moderate — operational, decay-checked |
| 7 | Patient advocacy / disease-foundation pages (note funding source) | Moderate — note bias |
| 8 | Recorded interviews with primary clinicians / patients | Moderate (primary source for personal narrative) |
| 9 | Wikipedia, WebMD, secondary aggregators | Low — verify upstream |
| 10 | Social media, anonymous posts, screenshots, transcribed verbal recollections | Lowest — attribute, do not assert |

**Screenshot/transcription rule:** Verbal recollections (e.g., "Dad says the hospital found no medical cause") must be attributed, never restated as fact. Specific instance: an "MRI" mentioned in a Dad-recounted hospital visit was wrongly stated as fact on a `/carlos` page; the source was a screenshot transcription with no actual record.

## GRADE Evidence-Quality Scale

Apply to every mechanism, efficacy, dosage, or contraindication claim.

| GRADE | Underlying Evidence | Example |
|-------|---------------------|---------|
| **High** | Systematic review / meta-analysis of RCTs; convergent independent confirmation | "Aspirin reduces 30-day post-MI mortality" |
| **Moderate** | Single well-powered RCT or multiple concordant cohort studies | "Drug X reduces HbA1c by ~0.8% over 12 weeks" |
| **Low** | Observational studies, case series, mechanistic plausibility from in vivo human data | "Compound Y appears to modulate Z based on pharmacokinetic studies" |
| **Very Low** | In vitro data only, animal studies, expert opinion, single case report | "Compound A binds receptor B in vitro" |

If no GRADE can be assigned (no source located, structurally unknowable), use **GAP** on the confidence axis and omit the GRADE label.

## Confidence Vocabulary (Claim Confidence — Axis 1)

| Label | Meaning | Required Evidence |
|-------|---------|-------------------|
| **VERIFIED** | Multiple independent sources confirm | ≥2 tier 1-5 sources OR 1 tier 1-2 with cross-check |
| **SUPPORTED** | Single reliable source, no contradictions | 1 tier 1-5 source |
| **INFERRED** | Logical deduction from verified premises | Reasoning chain documented; flag in text |
| **UNVERIFIED** | Source exists but not yet checked, or conflicting sources | Note "needs confirmation" in text |
| **GAP** (medical-legal alternative) | No source located, structurally unknowable | Note "no source located" in text — use for hospital-record-style gaps |

This preset uses **both** UNVERIFIED and GAP. UNVERIFIED for facts where a source should exist (drug label, court record) and we just haven't checked yet. GAP for facts that may be permanently unrecoverable (e.g., undocumented bedside conversations).

## AI Slop Gate

Every content change must pass a slop scan before commit.

**Hard fail (rewrite immediately):**
deep dive, game-changer, cutting-edge, elevate, delve, tapestry, holistic, robust, paradigm, groundbreaking, streamline, empower, harness, unleash, unpack, pivotal, crucial, bigger picture, smoking gun, synergy, arguably, it's worth noting, at the end of the day, in today's world, needless to say

**Soft warn (check context — legitimate medical use OK):**
leverage (as verb meaning "use"), comprehensive (as filler vs "comprehensive metabolic panel"), landscape (filler vs "treatment landscape"), stakeholder, navigate, facilitate, best practices, fundamentally, inherently

**How to run:** `bash scripts/slop_scan.sh`

**Allowlist:** add medical proper nouns and direct quotes to `.rdlc/slop-allowlist.txt` (e.g., FDA program names, trial acronyms).

## Audience Firewall (Standard Medical Mapping)

Multi-deliverable medical/legal repos MUST enforce per-audience boundaries. Below is the standard mapping; project-specific deliverables extend it.

| Deliverable | Audience | Forbidden Content |
|-------------|----------|-------------------|
| `output/clinical_*.{html,pdf}` | Clinician (PCP, specialist) | Litigation language, manufacturer marketing claims, system-failure rhetoric. Use GRADE-aligned uncertainty. "Screen, not assume" framing. |
| `output/patient_*.{html,pdf}` | Patient / caregiver | Salary figures, internal review notes, mock interview content, raw clinician-to-clinician notes, in vitro speculation without translation |
| `output/legal_*.{html,pdf}` | Counsel | Patient-comforting hedging that softens factual claims, clinician shorthand without expansion |
| `output/internal_*.md` | Team only | (none — full content; this is the source of truth others get filtered views of) |

The check belongs in the **generator** (Python/script that builds the deliverable), not just the source markdown. PDFs and HTML get forwarded without their source context — the boundary must hold at render time, not edit time.

## Cross-Model Review Protocol

For any published medical/legal deliverable:

1. **Pre-flight self-review.** Document every check at `.reviews/preflight-{review_id}.md`. Don't waste a Codex round on issues you could catch yourself.
2. **Mission-first handoff.** Write `.reviews/handoff.json` with: mission (2-3 sentences naming the actual outcome — e.g., "PCP must decide whether to continue current med"), success criteria, failure criteria, audience profile, stakes, files_changed, verification_checklist (file:line specific).
3. **Run the reviewer.** Codex CLI at `model_reasoning_effort=xhigh`. Lower settings miss subtle mechanism errors.
4. **Dialogue loop.** Per-finding response, increment round, status `PENDING_RECHECK`. 2 rounds sweet spot, 3 max. 4+ → escalate to human reviewer.
5. **Audience-as-reviewer for tone.** *"If you were the PCP being asked to continue a medication, where do you stop reading?"* Flushes out check-out moments document-level review misses.

Full protocol: `~/xdlc/docs/cross-model-review.md`.

## Fact Regression Tests

Every defect becomes a permanent check. Mechanism corrections in particular become permanent assertions — never let a previously-corrected mislabel return.

```bash
check_present "Creatine GABA-A note present" "creatine.*failed to activate GABA-A" "$DOC"
check_absent "No GABA-A agonist mislabel" "creatine.*GABA-A agonist" "$DOC"
check_present "GRADE label on mechanism claims" "GRADE: (Very Low|Low|Moderate|High)" "$DOC"
```

Run: `bash scripts/regression_test.sh`

The test count grows monotonically. Test counts in docs go stale — verify dynamically or guard with a count assertion.

## Certification Queue (Medical/Legal Specific)

Operational facts decay. Track them in `.rdlc/certification-queue.md`:

```markdown
| Provider/Fact | Last Checked | Recheck Date | Source | Status |
|---------------|--------------|--------------|--------|--------|
| Dr. X — AZ medical license | 2026-05-01 | 2026-08-01 | azmd.gov lookup | ACTIVE |
| Dr. Y — board cert, internal medicine | 2026-04-15 | 2026-10-15 | ABIM verify | ACTIVE |
```

Pre-publish gate: `scripts/regression_test.sh` includes a check that no row in this queue is past its `Recheck Date` for a fact referenced in the current deliverable. Stale = block.

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
├── regression_test.sh        # Fact regression suite (mechanism corrections are permanent)
├── slop_scan.sh              # Banned-phrase grep
└── generate_deliverable.py   # Multi-audience HTML generator (audience-firewalled)

research/                     # Topic-specific research files
evidence/
├── sources/                  # Raw source material with URLs and PMIDs
├── team_profiles/            # Provider eligibility / certification evidence
└── clinical/                 # Clinical study notes
output/                       # Final deliverables (HTML, PDF) — audience-firewalled
.reviews/                     # Review artifacts (handoff.json, preflight-*.md)
.rdlc/
├── slop-allowlist.txt        # Project-specific exclusions from slop scan
├── certification-queue.md    # Provider eligibility recheck schedule
└── version                   # Wizard version for drift detection
```

## Lessons Learned

*(Empty at install. Populate as the project earns rules. Anticheat-originating lessons above are the inherited baseline; add project-specific ones below.)*
