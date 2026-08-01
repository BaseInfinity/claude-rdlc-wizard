<!-- RDLC Wizard Version: 0.8.0 -->
<!-- Setup Date: TBD -->
<!-- Completed Steps: -->
<!-- Domain: automotive-audit -->
<!-- Preset Origin: tucson-investigation (diagnostic + dealer audit, multi-persona deliverables) -->

# RDLC Configuration — Automotive/Audit Preset

This is the **automotive-audit preset** of the RDLC canonical. Selected because the wizard detected automotive/audit signals in this repo (e.g., NHTSA references, TSB IDs, recall numbers like `24V-123`, VIN strings, dealer invoices, `recalls/` or `tsb/` directories).

If this was wrong, re-run `npx claude-rdlc-wizard init --preset general-research` (or another preset) to install a different canonical.

## What This Preset Adds Over the Generic RDLC

Diagnostic and dealer-audit research has lifecycle requirements that plain RDLC doesn't cover. From the `tucson-investigation` case study (36 commits, 111 persona tests, Hyundai Tucson AC compressor + dealer audit, 9-round Codex review loop):

- **Four-label split with GAP as a first-class label.** Mechanical investigations regularly hit facts that are *structurally unknowable* — service history before a previous owner, dealer notes that weren't kept, undocumented field repairs. GAP is not "we didn't try" (that's UNVERIFIED); it's "the record doesn't exist." Conflating the two destroys the audit's credibility.
- **Persona-based regression tests at the HTML level.** Each deliverable has a named persona (Dad / Mom / Indie Mechanic / Dealer Auditor) and a Playwright test that walks the page from that persona's perspective. Catches "this paragraph only makes sense if you already know X" — which document-level review misses.
- **Methodology-leak gate.** The investigation methodology (how we audited the dealer, what we asked the indie mechanic, what tools we used) does NOT belong in the dealer-facing or public deliverables. Methodology in the wrong audience's deliverable telegraphs the next ask and burns the audit.
- **Source-of-truth is the manufacturer TSB, not the forum thread.** Hyundai issues TSBs (Technical Service Bulletins) with specific symptoms, root cause, and repair procedure. Forum threads quote them; cite the TSB. Same for NHTSA: cite the recall number and PDF, not the news article about the recall.
- **9-round Codex review for high-stakes audit deliverables.** Most deliverables converge in 2-3 rounds. Dealer-audit material reviewed by the dealer's own counterparts took 9 rounds — every round caught a real issue. Don't shortcut.

## Wizard Version Tracking

| Property | Value |
|----------|-------|
| Wizard Version | 0.8.0 |
| Preset | automotive-audit |
| Last Updated | 2026-05-25 |
| Claude Code Baseline | v2.1.197+ (required for Sonnet 5 alias resolution) |
| Recommended Model | `claude-sonnet-5` (Sonnet 5) for primary work, GPT-5.6 Sol xhigh (Codex) for cross-model review |
| Recommended Effort | `max` for research drafting, `xhigh` for review (more rounds for dealer-audit material) |

## RDLC Enforcement (Automotive/Audit Variant)

### 1. Source Discipline
- Every claim has a citation, URL, or primary identifier (TSB number, NHTSA recall number, VIN, dealer invoice ID, service-record date)
- TSBs and recalls cited by ID (e.g., `TSB 24-01-049`, `NHTSA 24V-123`), not by forum quote
- Source-at-first-mention; subsequent references inherit

### 2. Four-Label Confidence Classification (DIRECT/SUPPORTED/INFERRED/GAP)

This preset uses tucson's four-label split — the **GAP** label is first-class because investigative work hits structurally unknowable facts constantly.

| Label | Meaning | Required Evidence |
|-------|---------|-------------------|
| **DIRECT** | First-hand observation, document, or measurement | The VIN report, the dealer invoice, the OBD scan, the photograph |
| **SUPPORTED** | Single corroborating source from a credible counterparty | TSB citation, NHTSA recall PDF, manufacturer service manual |
| **INFERRED** | Logical deduction from DIRECT/SUPPORTED facts | Reasoning chain documented; e.g., "compressor age inferred from TSB-mandated replacement window" |
| **GAP** | The record does not exist or is structurally unrecoverable | Previous-owner service history, undocumented field repair, missing dealer notes — note explicitly |

**GAP vs UNVERIFIED:** UNVERIFIED means "source should exist, haven't checked." GAP means "no source exists, possibly ever." Never substitute one for the other — the audit's credibility depends on the reader knowing which class a gap belongs to.

### 3. Cross-Model Review (Up to 9 Rounds for Audit Material)
- Claude (primary author) drafts; Codex GPT-5.6 Sol xhigh reviews
- Diagnostic deliverables: 2-3 rounds (normal)
- Dealer-audit deliverables: up to 9 rounds — every round catches real issues until the dealer-side counterpart can no longer find a foothold
- After 9 rounds with no certification → escalate to human reviewer

### 4. AI Slop Gate
- Banned phrase list scanned via `grep -E` before commit
- Automotive-specific soft warns: "comprehensive inspection", "industry-leading", "state-of-the-art", "best-in-class" (often dealer-marketing residue)
- Zero hits on tier-1 = pass

### 5. Audience-Firewall (Mandatory) + Methodology-Leak Gate
- Multi-deliverable repos MUST enforce per-audience boundaries
- Additionally: **methodology never leaks into adversarial-audience deliverables** (dealer-facing, public)
- Standard mapping below

### 6. Fact Regression Tests (Persona-Based)
- Every defect becomes a permanent regression check
- Special class: **persona regressions** — `tests/test_personas.py` walks each HTML deliverable from the perspective of its target persona (via Playwright)
- The ratchet only turns forward — gates get stricter, never looser

## Hooks Installed

| Hook | Trigger | Purpose |
|------|---------|---------|
| `rdlc-prompt-check.sh` | Every prompt | RDLC baseline reminder |
| `rdlc-instructions-check.sh` | Session start | Validates RDLC.md exists; prompts setup if missing |
| `slop-scan-pretool.sh` | Before Write/Edit | Blocks AI slop additions |
| `confidence-required.sh` | Before Write/Edit on `research/`, `evidence/` | Requires confidence label on new claims (keep recall/TSB notes under `research/` or `evidence/` — the hook only watches those segments) |
| `source-required.sh` | Before Write/Edit on research files | Requires source-at-first-mention (TSB/recall ID) |
| `audience-firewall.sh` | Before Write to `output/` | Blocks methodology + adversarial-audience content from leaking |

## Skills Available

| Skill | Invocation | Purpose |
|-------|------------|---------|
| RDLC | `/rdlc` | Full research workflow guidance |
| Setup | `/setup-rdlc` | Confidence-driven project setup |
| Update | `/update-rdlc` | Smart update with drift detection |
| Feedback | `/feedback-rdlc` | Privacy-first contribution loop |

## Source Hierarchy (Automotive/Audit — Manufacturer + Regulator on Top)

| Tier | Source Type | Weight |
|------|-------------|--------|
| 1 | Manufacturer TSBs (Technical Service Bulletins) by ID, recall PDFs by number, OEM service manuals | Highest — manufacturer first-party |
| 2 | NHTSA recall database (recalls.gov), NHTSA complaint database, EPA/CARB filings, state lemon-law records | Highest — regulator first-party |
| 3 | Dealer service records, dealer invoices, third-party CARFAX/AutoCheck reports with raw event data | High — operational primary |
| 4 | Independent diagnostic-shop reports, OBD-II scan tool exports, photo/video of the failure | High — direct observation |
| 5 | Manufacturer-authorized parts catalogs (RockAuto cross-reference, parts.hyundaiusa.com) | High — specs only |
| 6 | Professional automotive press (Car and Driver, MotorTrend, Edmunds technical write-ups) | Moderate — secondary |
| 7 | Mechanic/enthusiast forums with technical detail (NASIOC, RX8Club, model-specific) | Moderate — verify against TSB |
| 8 | YouTube technical channels (named mechanic with shop credentials) | Moderate (primary for visible procedure) |
| 9 | General review sites, Wikipedia, secondary aggregators | Low — verify upstream |
| 10 | Social media, anonymous posts, screenshots, transcribed verbal recollections (incl. dealer-said) | Lowest — attribute, do not assert |

**Dealer-said rule:** Anything a dealer service writer said verbally must be attributed ("Service writer said..."), never restated as fact. Service writers misremember, summarize, and sometimes shade.

## AI Slop Gate

Every content change must pass a slop scan before commit.

**Hard fail (rewrite immediately):**
deep dive, game-changer, cutting-edge, elevate, delve, tapestry, holistic, robust, paradigm, groundbreaking, streamline, empower, harness, unleash, unpack, pivotal, crucial, bigger picture, smoking gun, synergy, arguably, it's worth noting, at the end of the day, in today's world, needless to say

**Soft warn (automotive-specific — check context):**
comprehensive inspection, industry-leading, state-of-the-art, best-in-class, peace of mind, customer experience, world-class service, navigate (meaning "deal with"), leverage (as verb), facilitate, fundamentally

**How to run:** `bash scripts/slop_scan.sh`

**Allowlist:** add make/model/trim names, TSB IDs, technical part names, and direct quotes from the manufacturer to `.rdlc/slop-allowlist.txt`.

## Audience Firewall + Methodology Leak (Standard Automotive Mapping)

Diagnostic + dealer-audit repos almost always produce multiple deliverables for distinct audiences with adversarial relationships. The firewall is non-negotiable, AND methodology never appears in the dealer-facing or public-facing variant.

| Deliverable | Audience | Forbidden Content |
|-------------|----------|-------------------|
| `output/<owner>_cheatsheet.{html,pdf}` | The car owner / family member, non-technical | Methodology, audit framing, "things to verify the dealer didn't lie about", investigator-side language. Should read like a helpful summary, not an exposé. |
| `output/mechanic_*.{html,pdf}` | Independent mechanic the owner brings the car to | Investigator framing, dealer-audit content. Focus: symptoms, suspected systems, what to check, parts cross-reference. |
| `output/dealer_audit_*.{html,pdf}` | Dealer service department (handed during/after the audit) | Methodology, internal investigator notes, "what to ask next", suspected dealer-side gaps. Public-facing factual claims only. |
| `output/car_report.{html,pdf}` | Full investigation record (internal / archive) | (none — full content; source of truth others get filtered views of) |
| `output/public_*.{html,pdf}` | Public blog post / forum write-up | Everything in dealer/owner/mechanic rows above, PLUS personal info (VIN, name, address), PLUS investigator methodology that would let other dealers fingerprint the audit |

**Methodology-leak check:** the regression suite asserts that `output/dealer_*.{html,pdf}` and `output/public_*.{html,pdf}` contain ZERO mentions of `methodology|audit framework|investigation approach|what we checked|how we verified`.

The check belongs in the **generator** AND the regression suite — both layers. PDFs and HTML get forwarded without their source context — the boundary must hold at render time.

## Cross-Model Review Protocol

For any published diagnostic or dealer-audit deliverable:

1. **Pre-flight self-review.** Document at `.reviews/preflight-{review_id}.md`.
2. **Mission-first handoff.** `.reviews/handoff.json` with mission (2-3 sentences naming the outcome — e.g., "Eric walks into the dealer Monday knowing exactly which TSBs apply and what the previous shop already ruled out"), success criteria, failure criteria, audience profile, stakes (financial, safety, time), files_changed, verification_checklist.
3. **Run the reviewer.** Codex CLI at `model_reasoning_effort=xhigh`.
4. **Dialogue loop.** Diagnostic content: 2-3 rounds. Dealer-audit content: up to 9 rounds. Round 9 with no convergence → escalate.
5. **Persona-as-reviewer for owner-facing material.** "If you were the non-technical car owner reading this, where do you stop trusting that you understand?"

Full protocol: `~/xdlc/docs/cross-model-review.md`.

## Fact Regression Tests (Persona-Based)

Every defect becomes a permanent check. Special class: persona tests via Playwright walk each HTML from the named persona's perspective.

```bash
# Source verification (bash)
check_present "TSB ID cited for AC compressor claim" "TSB[- ]?[0-9]{2}-[0-9]{2}-[0-9]{3}" "$DOC"
check_present "NHTSA recall number cited" "[0-9]{2}V[- ]?[0-9]{3}|nhtsa\.gov/recalls" "$DOC"

# Methodology-leak prevention
check_absent "No methodology in dealer-facing deliverable" "methodology|audit framework|investigation approach|what we checked|how we verified" "$DEALER_DOC"
check_absent "No methodology in public deliverable" "methodology|audit framework|investigation approach" "$PUBLIC_DOC"

# Personal info leak
check_absent "No VIN in public deliverable" "[A-HJ-NPR-Z0-9]{17}" "$PUBLIC_DOC"
check_absent "No owner name in public deliverable" "$OWNER_NAME_PATTERN" "$PUBLIC_DOC"

# GAP discipline
check_absent_excl_review "No UNVERIFIED claim where GAP was meant" "UNVERIFIED.*previous owner|UNVERIFIED.*before purchase" "$DOC"
```

```python
# Persona regressions (pytest + Playwright)
# tests/test_personas.py
# Each persona walks each deliverable; failures surface "this paragraph only
# makes sense if you already know X" — which doc-level review misses.
def test_dad_cheatsheet_no_jargon(page):
    page.goto(CHEATSHEET_URL)
    text = page.text_content("body")
    assert "TSB" not in text or "Technical Service Bulletin" in text  # always expand acronyms
    assert "OEM" not in text or "manufacturer" in text
```

Run: `bash scripts/regression_test.sh && python -m pytest tests/test_personas.py -v`

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
├── regression_test.sh        # Fact regression suite (methodology-leak + persona)
├── slop_scan.sh              # Banned-phrase grep (automotive soft warns)
└── generate_deliverable.py   # Multi-audience generator (owner/mechanic/dealer/public)

tests/
├── test_personas.py          # Playwright walks each HTML from named-persona view
└── test_build_pipeline.py    # Build + freshness + methodology-leak checks

research/                     # Topic-specific research (e.g., ac_compressor_lifespan_research.md)
evidence/
├── sources/                  # Raw source material with URLs and TSB/recall IDs
├── recalls/                  # NHTSA recall PDFs by number
├── tsb/                      # Manufacturer TSBs by ID
└── service_history/          # Dealer invoices, shop reports, OBD scans
output/                       # Final deliverables — audience-firewalled, methodology-gated
.reviews/                     # Review artifacts (handoff.json, preflight-*.md)
.rdlc/
├── slop-allowlist.txt        # Project-specific exclusions
└── version                   # Wizard version for drift detection
```

## Lessons Learned

*(Empty at install. Populate as the project earns rules. Tucson-originating lessons above are the inherited baseline; add project-specific ones below.)*
