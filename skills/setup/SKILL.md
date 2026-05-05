---
name: setup-rdlc
description: RDLC setup wizard — scans the repo for research signals, builds confidence per data point, only asks what it can't figure out, generates RDLC.md and supporting scaffolds. Use for first-time RDLC setup or re-running setup.
argument-hint: [optional: regenerate | verify-only]
effort: high
---
# RDLC Setup Wizard — Confidence-Driven Research Configuration

## Task
$ARGUMENTS

## Purpose

Confidence-driven setup wizard. Scan the project, infer as much as possible, and only ask the user about what you can't figure out. The number of questions is DYNAMIC — it depends on how much you can detect.

**DO NOT ask a fixed list of questions. DO NOT ask what you already know.**

## MANDATORY FIRST ACTION: Read RDLC.md (Wizard Template)

Before doing ANYTHING else, Read the wizard's template at `${CLAUDE_PLUGIN_ROOT}/RDLC.md` (or the local clone equivalent). This is the source of truth for what gets installed. After reading, use it as the canonical for every step below.

## Execution Checklist

Follow these steps IN ORDER. Do not skip or combine.

### Step 1: Auto-Scan the Project

Scan for research signals:

**Directories indicating research repo:**
- `evidence/`, `evidence/sources/`, `evidence/profiles/`, `evidence/documents/`
- `research/` (lowercase_with_underscores .md files)
- `sources/`, `references/`, `citations/`
- `output/` with HTML or PDF deliverables
- `.reviews/` with handoff.json or review artifacts

**Existing RDLC-flavored conventions:**
- `*.md` files containing `VERIFIED|SUPPORTED|INFERRED|UNVERIFIED|GAP|DIRECT` (confidence labels already in use)
- `*.md` files with footnoted URLs or PMIDs (citation discipline)
- A `scripts/regression_test.sh` with `check_present`/`check_absent` patterns
- A `scripts/slop_scan.sh` or similar grep-based content gate
- `.reviews/handoff.json` or `.reviews/preflight-*.md` artifacts
- Cross-model review skill (`.claude/skills/codex-review/`) or similar

**Domain indicators (for domain-adaptive RDLC.md):**
- Medical/legal: `evidence/team_profiles/`, GRADE labels, PMIDs, DrugBank/ChEMBL/PubChem references → `medical-legal` preset
- Political/research: `evidence/policy_documents/`, FEC filings, organizational chart references → `political-research` preset
- Automotive/audit: NHTSA TSB references, dealer invoices, recall numbers → `automotive-audit` preset
- General research: default — everything else

**Existing tooling:**
- `claude-sdlc-wizard` already installed (look for `SDLC.md` + `.claude/hooks/sdlc-prompt-check.sh`) — RDLC pairs with it, doesn't replace it
- `AGENTS.md` (cross-tool agent-instructions) — RDLC overlaps and needs the dual-maintain decision
- `CLAUDE.md` already exists — RDLC adds an `## RDLC` section, doesn't overwrite

### Step 2: Build Confidence Map

For each configuration data point, assign a confidence level:

**Configuration Data Points:**

| Category | Data Point | How to Detect |
|----------|-----------|---------------|
| Domain | Project domain | Auto-detect from indicators above. Default: general research |
| Structure | Research source dir | `research/`, `sources/`, `evidence/sources/` |
| Structure | Output dir | `output/`, `dist/`, `build/` |
| Structure | Reviews dir | `.reviews/` exists or needs creation |
| Confidence | Confidence vocab in use | Grep for VERIFIED/SUPPORTED/INFERRED/UNVERIFIED in existing files |
| Confidence | Fourth label preference | UNVERIFIED (research, source should exist) vs GAP (investigation, structurally unknowable) — ALWAYS ASK if no detection |
| Sources | Primary databases referenced | DrugBank/ChEMBL/PubChem (medical), FEC/Congress (political), NHTSA (automotive), EDGAR (financial) |
| Tooling | Slop scan present | Look for `scripts/slop_scan.sh` or grep one-liner in SDLC.md/CLAUDE.md |
| Tooling | Regression suite present | `scripts/regression_test.sh` with `check_*` helpers |
| Tooling | Multi-deliverable generator | `scripts/generate_*.py` with config dict pattern |
| Tooling | Cross-model review configured | Codex CLI installed (`which codex`), `.reviews/handoff.json` schema in use |
| Audience | Number of deliverables | Count `output/*.html` or files matching deliverable naming |
| Audience | Audience boundaries needed | Multiple deliverables AND mixed audiences? — ALWAYS ASK |
| Pairing | claude-sdlc-wizard installed | Check for `SDLC.md` + `.claude/hooks/sdlc-prompt-check.sh` |
| Preferences | Slop allowlist needed | Project has direct quotes or proper nouns matching banned phrases? — ALWAYS ASK after scan |
| Preferences | Hard-block vs warn for hooks | Cannot detect — ALWAYS ASK (default: warn at v0.1) |

**Each data point has one of three states:**
- **RESOLVED (detected):** Found concrete evidence — confirm.
- **RESOLVED (inferred):** Found indirect evidence — present inference, let user confirm or correct.
- **UNRESOLVED:** No evidence found — ask the user directly.

**Preference data points** (fourth label, audience boundaries, hard-block mode, slop allowlist) are ALWAYS UNRESOLVED.

### Step 3: Present Findings and Fill Gaps

Present ALL detected values organized by state:

**RESOLVED (detected):** show what was found, bulk-confirm.
**RESOLVED (inferred):** show what was inferred with reasoning, ask to confirm or correct.
**UNRESOLVED:** ask the user directly — these are your only questions.

**The ready rule:** ready to generate files when ALL data points are resolved. A well-configured research repo might need 2-3 questions (just preferences). A bare repo might need 8-10. There is no fixed count.

DO NOT proceed to file generation until all data points are resolved.

### Step 4: Generate or Update RDLC.md

If `RDLC.md` does NOT exist: copy the template from `${CLAUDE_PLUGIN_ROOT}/templates/RDLC.md.template`, fill in metadata, source hierarchy adapted to detected domain, confidence vocabulary with chosen fourth label, audience-firewall section if multiple deliverables.

If `RDLC.md` DOES exist: never overwrite. Update only the metadata header. Surface drift in any sections the wizard manages and let the user pick adopt/skip per section.

### Step 5: Generate Hooks Directory

Copy hooks from `${CLAUDE_PLUGIN_ROOT}/hooks/` into `.claude/hooks/`:

- `_find-rdlc-root.sh`
- `rdlc-prompt-check.sh`
- `instructions-loaded-check.sh`
- `slop-scan-pretool.sh`
- `confidence-required.sh`
- `source-required.sh`
- `audience-firewall.sh`

Make them executable: `chmod +x .claude/hooks/*.sh`.

### Step 6: Update settings.json

Merge hook configuration into `.claude/settings.json`. Use a smart merge — don't overwrite existing `permissions` or `env` blocks. Add the RDLC hook entries to `hooks` arrays:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/rdlc-prompt-check.sh" }] }
    ],
    "PreToolUse": [
      { "matcher": "Write|Edit|MultiEdit", "hooks": [
        { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/slop-scan-pretool.sh" }
      ]}
    ],
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/instructions-loaded-check.sh" }] }
    ]
  }
}
```

If the user has `claude-sdlc-wizard` installed, RDLC hooks register *alongside* SDLC hooks. They do not conflict — different gates, different exit conditions.

### Step 7: Generate Scripts (if missing)

Copy templates from `${CLAUDE_PLUGIN_ROOT}/templates/` into `scripts/`:

- `regression_test.sh.template` → `scripts/regression_test.sh` (executable, with TODO markers for project-specific assertions)
- `slop_scan.sh.template` → `scripts/slop_scan.sh` (executable)
- `generate_deliverable.py.template` → `scripts/generate_deliverable.py` (with example deliverable config)

If any script already exists, do not overwrite — surface the diff and let user pick.

### Step 8: Generate .rdlc/ Directory

Create:

```
.rdlc/
├── slop-allowlist.txt   # Empty file with comment header
└── version              # File containing wizard version (0.1.0)
```

### Step 9: Memory Entry

Write a single `project_rdlc_install.md` to the consumer's memory namespace:

```markdown
---
name: rdlc-wizard installed
description: claude-rdlc-wizard v0.1.0 installed; consumer canonical at RDLC.md
type: project
---
RDLC wizard installed on YYYY-MM-DD. Domain: [detected]. Fourth-label choice: [UNVERIFIED|GAP].
Pairs with: [claude-sdlc-wizard if detected].

**Why:** Research repo earned the RDLC layer (sources, confidence, slop, audience-firewall) on top of the code SDLC layer.
**How to apply:** Invoke /rdlc for any research/fact-check/draft work. Run scripts/regression_test.sh before commit. Cross-model review for high-stakes deliverables.
```

### Step 10: Verify Installation

Run quick smoke checks:

- `RDLC.md` exists and parses (markdown syntax check via `awk`)
- `.claude/hooks/rdlc-prompt-check.sh` exists, executable, has correct shebang
- `.claude/settings.json` parses (`jq -e .` succeeds)
- `scripts/regression_test.sh` runs with --help or empty input without error
- `bash scripts/slop_scan.sh` runs and reports zero hits on the freshly installed RDLC.md (the wizard's own writing must pass its own gate)

If any check fails, surface the failure and offer a fix or rollback.

### Step 11: Restart Notice

Print:
> RDLC Wizard v0.1.0 installed.
>
> Hooks activate on next Claude Code restart. Run `/exit` then `claude` to reload.
>
> First steps:
> 1. Customize `RDLC.md` source hierarchy to match your project's evidence types
> 2. Add project-specific allowlist entries to `.rdlc/slop-allowlist.txt`
> 3. Replace TODO markers in `scripts/regression_test.sh` with assertions about your project's facts
> 4. Run `/rdlc` for the full workflow on your first research task

## Anti-Patterns

- **Asking before scanning.** First scan, then ask only what scan can't answer.
- **Overwriting customizations.** If a file exists, never overwrite — diff and ask.
- **Bundling SDLC and RDLC enforcement.** They register separately. Detect both, don't force one.
- **Copying templates without filling them in.** Templates have TODO markers; the wizard must fill domain-specific values during install, not leave the user to do it.
- **Skipping the smoke check.** Step 10 catches typos in the install path.

## When This Is Overkill

If the user is testing the wizard against a sandbox repo and just wants the files dropped, accept a `--minimal` flag that skips Steps 2-3 (no scan, no questions) and copies templates with sensible defaults. Never the default behavior — only opt-in.
