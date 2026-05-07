<!-- RDLC Wizard Version: 0.3.0 -->
<!-- Setup Date: TBD -->
<!-- Completed Steps: -->
<!-- Domain: research -->

# RDLC Configuration

This document is installed by `claude-rdlc-wizard` into the consumer repo. It is the canonical for "what RDLC enforces here." Edit it freely — `update-wizard` preserves your customizations and only touches the metadata header.

## Wizard Version Tracking

| Property | Value |
|----------|-------|
| Wizard Version | 0.3.0 |
| Last Updated | 2026-05-06 |
| Claude Code Baseline | v2.1.111+ (required for Opus 4.7 / `opus[1m]`) |
| Recommended Model | `opus[1m]` for primary work, `gpt-5.5 xhigh` (Codex) for cross-model review |
| Recommended Effort | `max` for research drafting, `xhigh` for review and verification |

## RDLC Enforcement

This repository uses the RDLC Wizard to enforce:

### 1. Source Discipline
- Every claim has a citation or URL
- Sources ranked by tier (see "Source Hierarchy" below)
- Source-at-first-mention; subsequent references inherit

### 2. Confidence Classification
- Every claim labeled VERIFIED / SUPPORTED / INFERRED / UNVERIFIED
- Labels are not optional; the hook blocks Write/Edit on research files without one
- Confidence escalates only when new sources land — never silently

### 3. Cross-Model Review
- Claude (primary author) drafts; a second model (Codex GPT-5.4 xhigh recommended) reviews
- Mission-first prompt structure: mission, success, failure, audience, stakes
- Convergence: 2 rounds is the sweet spot, 3 max

### 4. AI Slop Gate
- Banned phrase list scanned via `grep -E` before commit
- Hard fail (rewrite immediately) and soft warn (check context) tiers
- Zero hits = pass

### 5. Audience-Firewall
- Multi-deliverable repos enforce per-audience content boundaries
- Private content (interview salary, internal mock questions) cannot leak to public deliverables
- Enforced in the deliverable generator, not just the source pages

### 6. Fact Regression Tests
- Every defect found becomes a permanent regression check
- Test format: `check_present` and `check_absent` bash assertions on output files
- The ratchet only turns forward — gates get stricter, never looser

## Hooks Installed

| Hook | Trigger | Purpose |
|------|---------|---------|
| `rdlc-prompt-check.sh` | Every prompt | RDLC baseline reminder |
| `rdlc-instructions-check.sh` | Session start | Validates RDLC.md exists; prompts setup if missing |
| `slop-scan-pretool.sh` | Before Write/Edit | Blocks AI slop additions |
| `confidence-required.sh` | Before Write/Edit on `research/`, `evidence/` | Requires confidence label on new claims |
| `source-required.sh` | Before Write/Edit on research files | Requires source-at-first-mention |
| `audience-firewall.sh` | Before Write to `output/` | Blocks audience-private content from public deliverables |

## Skills Available

| Skill | Invocation | Purpose |
|-------|------------|---------|
| RDLC | `/rdlc` | Full research workflow guidance |
| Setup | `/setup-rdlc` | Confidence-driven project setup |
| Update | `/update-rdlc` | Smart update with drift detection |
| Feedback | `/feedback-rdlc` | Privacy-first contribution loop |

## Source Hierarchy

Higher tiers carry more weight when claims conflict.

| Tier | Source Type | Weight |
|------|-------------|--------|
| 1 | Primary databases (DrugBank, ChEMBL, PubChem, openFDA, EDGAR, USPTO, FEC) | Highest — authoritative |
| 2 | Government records, legislative archives, court filings | Highest — authoritative |
| 3 | Peer-reviewed papers (PubMed, arXiv with peer review) | High |
| 4 | Established news outlets with editorial standards | High |
| 5 | Official organizational sites (statesproject.org, anthropic.com) | High |
| 6 | Professional profiles (LinkedIn, TheOrg, Crunchbase) | Moderate |
| 7 | Watchdog/advocacy sites (note bias) | Moderate |
| 8 | Podcasts/interviews with primary subjects | Moderate (primary source) |
| 9 | Wikipedia, secondary aggregators | Low — verify upstream |
| 10 | Social media, anonymous posts, screenshots | Lowest — attribute, do not assert |

## Confidence Vocabulary

| Label | Meaning | Required Evidence |
|-------|---------|-------------------|
| **VERIFIED** | Multiple independent sources confirm | ≥2 tier 1-5 sources OR 1 tier 1-2 with cross-check |
| **SUPPORTED** | Single reliable source, no contradictions | 1 tier 1-5 source |
| **INFERRED** | Logical deduction from verified premises | Reasoning chain documented; flag in text |
| **UNVERIFIED** | Source exists but not yet checked, or conflicting sources | Note "needs confirmation" in text |
| **GAP** (alt) | No source located, structurally unknowable (use for investigation domains) | Note "no source located" in text |

Pick one alt for the fourth slot per project: UNVERIFIED if sources should exist, GAP if some facts cannot be recovered. Document the choice here.

## AI Slop Gate

Every content change must pass a slop scan before commit.

**Hard fail (rewrite immediately):**
deep dive, game-changer, cutting-edge, elevate, delve, tapestry, holistic, robust, paradigm, groundbreaking, streamline, empower, harness, unleash, unpack, pivotal, crucial, bigger picture, smoking gun, synergy, arguably, it's worth noting, at the end of the day, in today's world, needless to say

**Soft warn (check context — legitimate use OK):**
leverage (as verb meaning "use"), comprehensive (as filler), landscape (filler vs "competitive landscape"), stakeholder (when generic), navigate (meaning "deal with"), facilitate (filler), best practices (generic), fundamentally, inherently

**How to run:**
```bash
bash scripts/slop_scan.sh
```

Zero hits = pass. Any hit = review and rewrite.

**Allowlist:** project-specific proper nouns (mission pillar names, direct quotes) can be added to `.rdlc/slop-allowlist.txt` to suppress false positives. Lines in that file are excluded from the scan.

## Audience Firewall

Multi-deliverable repos must enforce per-audience boundaries. Each deliverable has its own assertion list of forbidden patterns.

Example mapping:

| Deliverable | Audience | Forbidden Content |
|-------------|----------|-------------------|
| `output/private_*.html` | Internal | (none — full content) |
| `output/public_*.html` | External | Salary figures, mock-interview content, private contact info, internal review notes |
| `output/clinical_*.pdf` | Medical | Litigation language, manufacturer marketing claims |

The check belongs in the *generator* (Python/script that builds the deliverable), not just the source markdown. PDFs and HTML get forwarded without their context — the boundary must hold at render time.

## Cross-Model Review Protocol

For high-stakes deliverables (anything published, anything legally adjacent, anything tone-sensitive):

1. **Pre-flight self-review.** `/code-review` equivalent for prose. Document every check at `.reviews/preflight-{review_id}.md`. Don't waste a Codex round on issues you could catch yourself.
2. **Mission-first handoff.** Write `.reviews/handoff.json` with: mission (2-3 sentences), success criteria, failure criteria, audience profile, stakes, files_changed, verification_checklist (file:line specific).
3. **Run the reviewer.** Codex CLI at `model_reasoning_effort=xhigh`. Always xhigh — lower settings miss subtle errors.
4. **Dialogue loop.** Per-finding response, increment round, status `PENDING_RECHECK`. Convergence: 2 rounds is the sweet spot, 3 max. After 3 still NOT CERTIFIED → escalate.
5. **Audience-as-reviewer variant.** For tone-sensitive content, prompt the reviewer to adopt the audience's mindset: *"If you were [audience], when do you stop reading?"* — flushes out check-out moments document-level review never finds.

Full protocol: `~/xdlc/docs/cross-model-review.md`.

## Fact Regression Tests

Every defect becomes a permanent check. Test format:

```bash
check_present "Claim X exists" "expected pattern" "$DOC"
check_absent "No fabrication Y" "forbidden pattern" "$DOC"
check_absent_excl_review "No overclaim Z outside review section" "pattern" "$DOC"
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
├── regression_test.sh        # Fact regression suite
├── slop_scan.sh              # Banned-phrase grep
└── generate_deliverable.py   # Multi-document HTML generator (audience-firewalled)

research/                     # Topic-specific research files (lowercase_with_underscores.md)
evidence/
├── sources/                  # Raw source material with URLs
└── ...                       # Domain-specific subdirs
output/                       # Final deliverables (HTML, PDF)
.reviews/                     # Review artifacts (handoff.json, preflight-*.md)
.rdlc/
└── slop-allowlist.txt        # Project-specific exclusions from slop scan
```

## Lessons Learned

(Empty at install. Populate as the project earns rules. Format mirrors `~/sdlc-wizard/SDLC.md` "Lessons Learned" — one bullet per gotcha, cite the originating PR or incident date.)
