# Architecture

How claude-rdlc-wizard fits together.

## The two-wizard pattern

A research repo runs **two lifecycles in parallel**:

```
┌─────────────────────────────────────┐
│   Research repo (consumer)          │
│                                     │
│   ┌───────────────┐ ┌─────────────┐ │
│   │ claude-sdlc-  │ │ claude-rdlc-│ │
│   │ wizard        │ │ wizard      │ │
│   │ (code layer)  │ │ (research   │ │
│   │               │ │  layer)     │ │
│   └───────────────┘ └─────────────┘ │
│        SDLC.md         RDLC.md      │
│        /sdlc skill     /rdlc skill  │
│        TDD hooks       Slop hooks   │
│        Code tests      Fact tests   │
└─────────────────────────────────────┘
```

SDLC handles "is this code correct" (TDD, lint, tests pass). RDLC handles "is this research correct" (sources cited, confidence labeled, slop absent, audiences firewalled). Both can run; neither subsumes the other.

## Repo layout

```
claude-rdlc-wizard/
├── README.md               # Public-facing intro
├── AI_SETUP_LANES.md       # Recommended model/effort lanes (A/B/C/D)
├── CLAUDE.md               # Wizard self-instructions (this file's neighbor)
├── ARCHITECTURE.md         # This file
├── CHANGELOG.md            # Version history
├── ROADMAP.md              # Queued for v0.2+
├── RDLC.md                 # Consumer-installable canonical (template lives in templates/RDLC.md.template)
├── package.json            # npm metadata
├── install.sh              # One-line installer
├── skills/
│   ├── rdlc/SKILL.md       # Doing-the-work skill
│   ├── setup/SKILL.md      # Setup wizard
│   ├── update/SKILL.md     # Update with drift detection
│   └── feedback/SKILL.md   # GitHub-issue feedback loop
├── hooks/
│   ├── hooks.json          # Hook registration manifest
│   ├── _find-rdlc-root.sh  # Shared helper (sourced)
│   ├── rdlc-prompt-check.sh        # UserPromptSubmit baseline
│   ├── slop-scan-pretool.sh        # PreToolUse Write/Edit slop gate
│   ├── confidence-required.sh      # PreToolUse claim-without-label gate
│   ├── source-required.sh          # PreToolUse source-at-first-mention gate
│   ├── audience-firewall.sh        # PreToolUse audience-leak gate
│   └── rdlc-instructions-check.sh # SessionStart RDLC.md presence check
├── templates/
│   ├── RDLC.md.template
│   ├── regression_test.sh.template
│   ├── slop_scan.sh.template
│   ├── generate_deliverable.py.template
│   ├── slop-allowlist.txt.template
│   └── audience-firewall.conf.template
├── presets/                # Per-domain RDLC.md flavors (medical-legal, political, automotive)
├── cli/                    # npm CLI (init/check/update) + settings.json template
├── .claude-plugin/         # Plugin manifest
└── tests/                  # Bash + jq test fixtures
```

## Skill triple (per xdlc/docs/skill-triple-pattern.md)

| Skill | Direction | Mutates | Body invariant |
|-------|-----------|---------|----------------|
| `setup` | upstream → consumer (first time) | consumer repo (scaffold) | Creates `RDLC.md` body; never edits an existing body |
| `update` | upstream → consumer (ongoing) | consumer metadata header + managed files | Never edits the consumer's `RDLC.md` body — only metadata + side files |
| `feedback` | consumer → upstream | nothing in the consumer except an append-only log | Never writes to the consumer's `RDLC.md` at all |

Three skills, three different trust footprints. Bundling them would conflate the invariants.

## Hook architecture

All hooks are POSIX bash, no external dependencies beyond `grep -E`, `jq`, and standard utilities. They follow the same shape:

1. **Walk up from CWD** to find the nearest `RDLC.md` (monorepo support)
2. **Exit silently** if not in an RDLC repo (no-op in code-only repos)
3. **Read JSON payload from stdin** (when present, e.g., for `PreToolUse`)
4. **Apply the gate**: grep, classify, then exit 0 (allow, silent), exit 1 (warn — stderr shown to the user, tool call proceeds), or exit 2 (block — stderr fed back to Claude as the refusal reason; strict mode)

| Hook | Trigger | Gate |
|------|---------|------|
| `rdlc-prompt-check.sh` | UserPromptSubmit | Print RDLC baseline reminder |
| `rdlc-instructions-check.sh` | SessionStart | Confirm `RDLC.md` exists; if not, prompt setup |
| `slop-scan-pretool.sh` | PreToolUse Write/Edit | Block if banned phrases in new content |
| `confidence-required.sh` | PreToolUse Write/Edit on `research/`,`evidence/` | Block if a new claim lacks a confidence label |
| `source-required.sh` | PreToolUse Write/Edit on research files | Block if a claim is added without a citation/URL |
| `audience-firewall.sh` | PreToolUse Write to `output/` deliverables | Block if private content is being added to a public deliverable |

Hooks are advisory by default — a triggered gate exits 1 with the warning on stderr (visible to the user, non-blocking) unless the user opts into hard-block mode via `RDLC_HOOKS_STRICT=1`, which exits 2 with the reason on stderr (fed back to Claude). Soft mode is the default until consumer repos earn the strict gate through use. Strict mode fails closed: a half-installed repo (hooks present, RDLC.md missing) or a missing `jq` blocks rather than silently disabling enforcement.

## Templates

Templates are _scaffolds_, not finished implementations. The consumer repo customizes them. Each ships with TODO markers and example assertions that the consumer replaces.

| Template | Source | What it scaffolds |
|----------|--------|-------------------|
| `regression_test.sh.template` | states-project-research/scripts/regression_test.sh | Bash `check_present`/`check_absent` fact regressions |
| `slop_scan.sh.template` | states-project-research/SDLC.md slop section | One-liner banned-phrase grep |
| `generate_deliverable.py.template` | states-project-research/scripts/generate_pdf.py | Multi-document HTML generator with audience boundary |
| `RDLC.md.template` | this repo's RDLC.md | Consumer canonical |
| `slop-allowlist.txt.template` | states-project-research | Comment-only scaffold for project-specific slop exemptions |
| `audience-firewall.conf.template` | states-project-research audience boundary | Comment-only scaffold for per-deliverable forbidden-pattern rules |

## Why templates were ported (vs. "mine in place")

The original v0 rule from `PATTERNS.md` says *"Reusable artifacts still live only in their source repos. Mine them in place."* That works when humans are doing the mining. It does not work when a wizard's `setup` skill needs to install something — the skill cannot reach into a private case-study repo's filesystem.

So at the moment claude-rdlc-wizard exists, the v0 rule is superseded by the v0.1.0 wizard's installation needs. The contradiction is documented in `CHANGELOG.md`. The case-study repos remain authoritative for their own evolutions; this wizard ships the *generalized scaffold* extracted from them, not their full content.

## Memory namespacing

Per `~/xdlc/README.md`, each repo gets its own auto-memory namespace:

- This repo: `~/.claude/projects/-Users-stefanayala-claude-rdlc-wizard/memory/`
- A consumer repo `~/foo-research/`: `~/.claude/projects/-Users-stefanayala-foo-research/memory/`

The wizard's `setup` skill writes a single `project_*` memory entry to the consumer namespace flagging the install (`project_rdlc_install.md`). The `feedback` skill reads memories cross-namespace to surface candidate earned rules for upstream contribution.

## Dogfooding

This repo's own writing is held to the slop gate the wizard installs in consumers. CI (when set up) will run `templates/slop_scan.sh.template` against every `*.md` file in this repo before merge. Failures block the PR.

## Future architecture changes (deferred)

- **Codex adapter** — `codex-rdlc-wizard` parallel package for AGENTS.md / `.codex/hooks.json`
- **L-code enumeration** — once enough hook-block incidents accumulate to warrant stable IDs (anticheat A–G, tucson L1–L15 are the precedent)
- **Setup scan refinement** — currently uses the 5-row signal table from xdlc/docs/cross-domain-concerns.md; will refine after first non-originating consumer
