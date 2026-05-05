# RDLC Extraction Notes — v0.1.0 Wizard Build

> **Consolidation note (2026-05-04):** This file was previously `~/rdlc/EXTRACTION_NOTES.md`. After the v0.1.0 wizard shipped, `~/rdlc/` was retired and consolidated into this repo. References to `~/rdlc/<file>` now point to in-repo files (e.g., `~/rdlc/README.md` → `PATTERNS.md`). This file is the build journal — preserved for the lessons earned during extraction.

> Session handoff document. Captures what was learned during the **2026-05-04** extraction of patterns into the working wizard at this repo (commit `396482e`). A future session opening this repo can read [PATTERNS.md](PATTERNS.md) for the pattern catalog, [CASE_STUDIES.md](CASE_STUDIES.md) for proof-point cross-index, and this file for *what we learned during the actual extraction*.

## What shipped (claude-rdlc-wizard v0.1.0)

| Layer | Files | Notes |
|-------|-------|-------|
| Docs | 5 | README, CHANGELOG, CLAUDE.md, ARCHITECTURE.md, ROADMAP.md |
| Canonical | 1 | `RDLC.md` (consumer-installable) |
| Skills | 4 | `rdlc` (650-line doing-the-work), `setup`, `update`, `feedback` — skill triple per `~/xdlc/docs/skill-triple-pattern.md` |
| Hooks | 7 + json | `rdlc-prompt-check`, `instructions-loaded-check`, `slop-scan-pretool`, `confidence-required`, `source-required`, `audience-firewall`, `_find-rdlc-root.sh` helper |
| Templates | 6 | `RDLC.md`, `regression_test.sh`, `slop_scan.sh`, `generate_deliverable.py`, `slop-allowlist.txt`, `audience-firewall.conf` |
| Tests | 3 suites | 28 assertions, all green; test-hooks / test-templates / test-slop-scan |
| Install | 2 | `install.sh` (with `--pair` flag), `package.json` |
| Plugin | 1 | `.claude-plugin/plugin.json` for CC plugin format |

Total: 31 files, ~3,200 lines, single commit `396482e`.

## Two rules from the v0 scope that got superseded by the build

### 1. "Mine in place" → "Templates ported"

The original v0 rule (still in [README.md](README.md) "v0 Scope" section as of this writing) said:

> No canonical templates ported out of source repos. Reusable artifacts (anticheat's `REVIEW_MATRIX.md`, states-project's `regression_test.sh`, tucson's `ADLC.md`) still live only in their source repos. Mine them in place.

That rule held while `~/rdlc/` was a documentation-only repo. It does not survive a wizard. A wizard's `setup` skill cannot reach into a private case-study repo to fetch `regression_test.sh` at install time. So at the moment a wizard exists, templates have to be ported into the wizard's own `templates/` directory.

What was ported into `~/claude-rdlc-wizard/templates/`:
- `regression_test.sh.template` (from `~/states-project-research/scripts/regression_test.sh` — stripped TSP-specific assertions, kept `check_present`/`check_absent`/`check_absent_excl_review` helpers, added confidence-label and source-citation gate sections)
- `slop_scan.sh.template` (formalized from `~/states-project-research/SDLC.md` slop one-liner; added two-tier hard-fail/soft-warn structure with allowlist support)
- `generate_deliverable.py.template` (skeleton from `~/states-project-research/scripts/generate_pdf.py` — kept the `DELIVERABLE_CONFIGS` dict pattern + audience-firewall enforcement; stripped TSP-specific content)
- `RDLC.md.template` (consumer canonical seed)
- `audience-firewall.conf.template` (new — formalizes the per-deliverable forbidden-pattern config)
- `slop-allowlist.txt.template` (new — addresses the meta-issue described below)

The originating case-study repos remain authoritative for their own evolutions. The wizard ships the *generalized scaffold* extracted from them.

### 2. "Skills first → wizard later" → "Wizard ships at v0.1, graduation deferred"

The rdlc README's stated v1 graduation criterion was:

> a fourth case study consumes patterns from here (not just from its source repo).

That gate was skipped by shipping v0.1.0. Justification (recorded in `~/claude-rdlc-wizard/CHANGELOG.md`):

> GDLC followed the same path with `claude-gdlc-wizard` v0.1.0 — the wizard ships *first* so a fourth consumer has something to install. Graduation remains a separate later milestone tied to a non-originating consumer adopting the wizard and producing an earned rule the first three didn't.

The xdlc/docs/skill-triple-pattern.md "v0.3.0 split" is the formal version of this distinction:
- **Distribution-readiness** (the wizard is installable) — only needs one case study's patterns to ship
- **Framework-graduation** (an earned rule from a non-originating consumer) — needs the second-consumer evidence

v0.1.0 cleared distribution-readiness. Graduation is now its own milestone, tracked at `~/claude-rdlc-wizard/ROADMAP.md` v1.0.

## Lessons earned during the build

### Lesson 1: The slop gate has a meta-problem (and the fix is a per-project allowlist)

The wizard's own documentation defines the banned-phrase list. Lines that *enumerate* the bans triggered the slop scan when run against the wizard's own files. Two RDLC.md lines and one CLAUDE.md line all hit the gate.

**Fix shipped:** `.rdlc/slop-allowlist.txt` mechanism — fragments unique to documentation-defining lines are added to a per-project allowlist; the slop scan filters lines matching any allowlist entry via `grep -viE`.

**Pattern that emerged:** every wizard-of-X (where X has a content-quality gate) faces the same meta-problem. The wizard documents the gate, which means it documents the bans, which means its own docs trigger its own gate. Self-allowlisting is the canonical solution. Document this pattern in any future content-quality-gate wizards.

The `~/claude-rdlc-wizard/.rdlc/slop-allowlist.txt` file is the canonical example. Three entries cover the bans-list line, the soft-warn line, and the meta-explanation paragraph in CLAUDE.md.

### Lesson 2: Two-tier slop gate (hard-fail + soft-warn) is materially better than one tier

The states-project-research SDLC.md already separated the two tiers, but it wasn't shipped as code. Building it as a working scanner exposed the value:

- **Hard-fail tier** (24 phrases) blocks. Zero false positives in dogfood — every hit was real.
- **Soft-warn tier** (9 phrases including `leverage`, `comprehensive`, `landscape`, `stakeholder`, `navigate`) flags but does not block. In the wizard's own docs: 2 soft-warn hits (a code identifier `competitive_landscape` and the phrase `stakeholder priority` in a memory-audit table). Both legitimate domain context — hard-fail would have given false positives.

**Pattern that emerged:** any rule with context-dependent legitimacy needs the two-tier shape. Don't collapse them.

### Lesson 3: `RDLC_HOOKS_STRICT=1` env var pattern — start lenient, ratchet up

All hooks default to soft-warn at v0.1.0. Setting `RDLC_HOOKS_STRICT=1` promotes them to hard-block (exit 2 sends stderr to Claude as a tool refusal).

**Why ship lenient:** the gates are heuristic. The confidence-required gate uses an awk-counted "claim-shaped sentence" heuristic that is intentionally lenient — many legitimate edits add prose that isn't a claim. Hard-blocking on a heuristic at v0.1 punishes real work. Soft-warning lets users see the gate's behavior and develop trust before it gets teeth.

**Pattern that emerged:** new-wizard hooks should default to soft-warn, opt-in to hard-block. The opt-in pattern (env var or settings flag) is the graduation path — when a consumer's heuristic accuracy is high enough that hard-block doesn't punish real work, they flip the flag.

### Lesson 4: Self-dogfooding catches issues no test suite would

The wizard's own writing was scanned by its own slop gate before commit. That caught:

1. The meta-problem above (banned-list lines triggering the gate)
2. One legitimate hard-fail hit (which became the test fixture for Lesson 1's allowlist)
3. Two soft-warn hits in legitimate code identifiers (validated the soft-warn-not-block design)

None of these would have been caught by unit tests on the scanner. They required *real content the wizard would actually generate*. The test-slop-scan.sh suite covers the scanner mechanics; dogfooding covers whether the scanner's calibration is correct.

**Pattern that emerged:** the dogfood-your-own-gate test is a wizard-level hygiene minimum. Add it to the v0 release checklist for every future DLC wizard.

### Lesson 5: The skill-triple invariants hold under real construction

The skill-triple-pattern.md doc enumerated invariants:
- `setup`: creates body content; never edits an existing body
- `update`: never edits the body — only metadata + side files
- `feedback`: never writes to the consumer's body at all

Building the three skills with these invariants in mind: they held. The `update` skill explicitly excludes the `RDLC.md` body from drift classification — only the metadata header is managed. The `feedback` skill writes only to a separate append-only log (`.rdlc/feedback-log.md`) and never reads citations, allowlist entries, or research content.

**Pattern that emerged:** the invariants are not just descriptive — they're *implementable*. Future DLC wizards can encode them directly in the skill files (e.g., the update skill's body invariant is enforced by hashing the metadata header, not the body, when computing drift).

### Lesson 6: The audience-firewall config format

Format that emerged after writing the hook:

```
<deliverable-glob>|<forbidden-pattern>|<reason>
```

Three pipe-separated fields. The `reason` field is load-bearing — when the gate trips, the user sees *why* the content is forbidden, not just *that* it is. Without the reason, every gate trip becomes a small mystery the user has to re-research.

**Pattern that emerged:** any rule-config format should require a human-readable reason field. "Why" is the load-bearing column, not "what."

This format choice should be canonical for v0.x — future versions don't drift unless there's strong reason.

### Lesson 7: Hook architecture decisions worth canonizing

These emerged organically during the build but deserve to be ratchet-locked:

1. **CWD walk-up to find RDLC.md.** Every hook walks up from `${PWD}` to find `RDLC.md`. Monorepo support; silent exit outside RDLC project. Code in `_find-rdlc-root.sh`.

2. **Silent exit outside RDLC project.** Hooks coexist with code-only repos (where claude-sdlc-wizard runs alone) without spurious output. The check is `find_rdlc_root || exit 0`.

3. **`dedupe_plugin_or_project` helper.** When both a project's local hook and the plugin-installed hook fire (e.g. user has `claude-rdlc-wizard` installed both globally and per-project), the plugin yields. Prevents 2× output per hook fire. Pattern lifted directly from sdlc-wizard's `_find-sdlc-root.sh`.

4. **Drain stdin when not used.** UserPromptSubmit can pipe a JSON payload; if the hook doesn't use it, draining via `cat >/dev/null` prevents downstream pipe issues.

5. **jq dependency optional.** If `jq` isn't installed, hooks exit silently rather than fail. Reasoning: the wizard installs into research repos that may not have jq; failing loudly defeats the soft-warn philosophy.

6. **All hooks: `set -uo pipefail`, NOT `set -euo pipefail`.** Hooks must NEVER error-exit on grep returning nothing — that's a normal, valid case. The `e` flag breaks too many things in research-content greps. Document this carefully; future contributors will be tempted to add it back.

### Lesson 8: Three-tier smoke tests are the wizard hygiene minimum

The build shipped three test suites:

1. **test-hooks.sh** (19 assertions) — do hooks have correct shebang, are they executable, does hooks.json parse, does each hook handle empty stdin, does each hook exit silently outside an RDLC project
2. **test-templates.sh** (6 assertions) — do templates have correct shebangs, do they parse (Python via ast.parse, markdown via ATX header presence), does the consumer canonical have the wizard-version comment
3. **test-slop-scan.sh** (3 assertions) — does clean content pass, do hard-fail phrases produce exit 1, does the allowlist suppress false positives

This three-tier pattern (mechanics / parseability / end-to-end) covers the wizard's surface area without being expensive. Total runtime: <5 seconds.

**Pattern that emerged:** future DLC wizards should ship the same three-tier minimum at v0.1.

## What was NOT shipped (deferred to later versions)

| Feature | Deferred to | Reason |
|---------|-------------|--------|
| npm CLI binary (`cli/bin/rdlc-wizard.js`) | v0.2 | Setup skill currently uses inline Write loops; CLI emerges when a 4th consumer needs install-without-clone |
| Codex adapter (`codex-rdlc-wizard`) | v0.4 | Host adapter pattern — wait for a Codex-only RDLC consumer |
| Per-domain presets (medical/legal, political, automotive, journalism) | v0.6 | Earn through use, not predict upfront |
| L-code enumeration (RDLC's own Lx codes) | v0.5+ | anticheat earned A–G, tucson earned L1–L15. RDLC will earn its own through hook-block incidents |
| Setup scan refinement | v0.3 | Currently uses xdlc/docs/cross-domain-concerns.md's 5-row signal table; refines after first non-originating consumer misclassifies |
| Public npm registry publish | v1.0 | Tied to graduation milestone |

## What a future session in `~/rdlc/` should do

When a future session opens this repo, the chain is:

1. **Read [README.md](README.md)** — patterns + lessons by case study
2. **Read [CASE_STUDIES.md](CASE_STUDIES.md)** — what each of the 3 proof points proved
3. **Read this file** — what was learned building the wizard
4. **Check `~/claude-rdlc-wizard/`** — current wizard state, version, ROADMAP
5. **Check `~/xdlc/README.md`** — registry status (whether the RDLC row reflects v0.1.0)

**Pending follow-ups for the rdlc framework itself:**

- [ ] Update [README.md](README.md) "What This Will Be" → "What This Is" (the wizard exists)
- [ ] Update [README.md](README.md) "v0 Scope" → mark historical, point at this file for the actual extraction record
- [ ] Update [README.md](README.md) "Hooks It Would Install" → "Hooks It Installs" (with link to wizard repo)
- [ ] Update [README.md](README.md) "Skills It Would Provide" → similar
- [ ] Add a "Wizard Status" subsection near the top linking to the wizard repo
- [ ] (Lower priority) Register the wizard in `~/xdlc/README.md` framework status table — change RDLC row's `Skill` column from `no` to `/rdlc, /setup-rdlc, /update-rdlc, /feedback-rdlc`

The README updates are partially handled in the same commit that adds this file — see the `~/rdlc/` git log.

**Pending follow-ups for the wizard:**

- [ ] First non-originating consumer adopts (graduation candidate)
- [ ] When that happens, capture the earned rule back here and in the wizard's CHANGELOG
- [ ] If the rule generalizes to ≥2 siblings, promote to xdlc as a cross-DLC pattern

## Cross-references

- Wizard repo: `~/claude-rdlc-wizard/` (commit `396482e`)
- Pattern source: this repo's [README.md](README.md)
- Case studies: this repo's [CASE_STUDIES.md](CASE_STUDIES.md)
- Skill triple spec: `~/xdlc/docs/skill-triple-pattern.md`
- Cross-model review pattern: `~/xdlc/docs/cross-model-review.md`
- Cross-domain concerns: `~/xdlc/docs/cross-domain-concerns.md`
- Originating case studies:
  - `~/anticheat/` (medical/legal evidence)
  - `~/states-project-research/` (political/interview prep)
  - `~/tucson-investigation/` (automotive diagnostic)

## Memory pointers (for future sessions in `~/rdlc/`)

Per `~/xdlc/README.md`'s memory-namespacing pattern:

- This repo's namespace: `~/.claude/projects/-Users-stefanayala-rdlc/memory/`
- Wizard repo's namespace: `~/.claude/projects/-Users-stefanayala-claude-rdlc-wizard/memory/`
- Originating case-study namespaces (mine cross-namespace for precedent):
  - `~/.claude/projects/-Users-stefanayala-anticheat/memory/`
  - `~/.claude/projects/-Users-stefanayala-states-project-research/memory/`
  - `~/.claude/projects/-Users-stefanayala-tucson-investigation/memory/`

When a future session needs to understand a wizard decision, the originating case study's memory often has the "why" (e.g. why the regression suite uses bash not pytest — states-project's memory will have that).
