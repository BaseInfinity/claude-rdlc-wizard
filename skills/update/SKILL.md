---
name: update-rdlc
description: Smart update for claude-rdlc-wizard — shows changelog, compares files, lets you selectively adopt changes while preserving customizations.
argument-hint: [optional: check-only | force-all]
effort: high
---
# Update RDLC Wizard — Smart Drift Reconciliation

## Task
$ARGUMENTS

## Purpose

Guided update assistant. Check the user's installed version, show what changed upstream, walk through selectively adopting updates while preserving customizations. **DO NOT blindly overwrite files.** Show diffs and let the user decide.

## Body Invariant (Skill Triple Pattern)

This skill mutates the consumer's `.claude/hooks/`, `.claude/settings.json`, `scripts/`, and the metadata header of `RDLC.md`. It NEVER edits the body of `RDLC.md` (the part below the metadata comment). The consumer's RDLC.md body is sacred — customizations there are the whole point.

If the upstream RDLC.md template has a new section, surface the diff and offer it as a separate "consider adopting" block. Don't auto-merge into the body.

## MANDATORY FIRST ACTION: Read CHANGELOG

Before proceeding, fetch the upstream `CHANGELOG.md` to know what's new:

```bash
curl -fsS https://raw.githubusercontent.com/BaseInfinity/claude-rdlc-wizard/main/CHANGELOG.md
```

Cache the result; reuse in Step 3.

## Execution Checklist

### Step 1: Read Installed Version

Read `RDLC.md` and extract from the metadata comment:
```
<!-- RDLC Wizard Version: X.X.X -->
<!-- Setup Date: ... -->
<!-- Completed Steps: ... -->
```

No version comment → treat as `0.0.0` (suggest `/setup-rdlc` instead).

### Step 2: Check CLI Version

Mirrors `claude-sdlc-wizard`'s Step 1.5:

1. Detect global install: `npm ls -g claude-rdlc-wizard --json --depth=0`
2. Detect npx cache: find every `package.json` under `~/.npm/_npx` matching `*claude-rdlc-wizard*`
3. Compare with semver-aware logic (NOT `sort -V` — it mishandles prereleases)
4. If installed < latest, surface upgrade options A/B/C (refresh CLI / one-shot init --force / skip)

### Step 3: Compare Versions and Show What Changed

Parse CHANGELOG entries between installed and latest. Present:

```
Installed: 0.1.0
Latest:    0.2.0

What changed:
- [0.2.0] npm CLI shipped — `npx claude-rdlc-wizard init` now drops files via the CLI instead of inline Write loops
- [0.2.0] Added `cli/bin/rdlc-wizard.js` with init/check/update commands
- ...

Update? [y/N/show-diffs]
```

### Step 4: Per-File Drift Classification

For each managed file (skills/, hooks/, scripts/, .claude/settings.json), classify:

| State | Meaning | Action |
|-------|---------|--------|
| **MATCH** | Consumer file matches upstream verbatim | No-op |
| **CUSTOMIZED** | Consumer edited the file intentionally | Show diff; user decides (adopt / skip / merge) |
| **MISSING** | File expected by wizard doesn't exist locally | Offer install |
| **DRIFT** | File exists but has problems (wrong permissions, malformed metadata) | Flag + offer fix |

The consumer's `RDLC.md` body is excluded from drift classification — only the metadata header is managed.

### Step 5: Per-File Decision

For each non-MATCH file, present a 3-line summary and prompt:

```
File: scripts/regression_test.sh
Status: CUSTOMIZED (you added 47 project-specific assertions)
Upstream change: helper functions hardened against macOS bash 3.x

Diff (10 lines):
+ # bash 3.x compat: declare -A removed
- declare -A FAIL_REASONS
- ...
+ # use case statement instead

Action? [a]dopt upstream / [s]kip / [m]erge manually / [d]iff full
```

Default: skip. The consumer's customizations are the load-bearing part; the upstream change is opt-in.

### Step 6: Apply Selected Updates

Apply each chosen update atomically. If anything fails:
- Roll back the partial update (move `.bak` files back)
- Surface the error
- Leave version metadata at pre-update value (next retry is idempotent)

### Step 7: Bump Version

Last step. Update the metadata header in `RDLC.md`:

```
<!-- RDLC Wizard Version: 0.2.0 -->
<!-- Setup Date: 2026-05-04 -->
<!-- Last Updated: 2026-MM-DD -->
<!-- Completed Steps: ... -->
```

Body is untouched.

### Step 8: Verify

Run smoke checks (mirror Step 9 of setup):
- `RDLC.md` parses
- `.claude/hooks/rdlc-prompt-check.sh` exists and is executable
- `.claude/settings.json` is valid JSON (`jq -e .`)
- `bash scripts/slop_scan.sh` runs without error

Surface any failure; offer rollback to backed-up versions.

### Step 9: Restart Notice

```
RDLC Wizard updated: 0.1.0 → 0.2.0

X files adopted, Y skipped, Z merged manually.

Restart Claude Code to activate updated hooks: /exit then claude.
```

## One-Time Migrations

Some upgrades introduce new files (e.g., v0.4 adds `feedback-log.md`). For one-time migrations:

- Update can CREATE new files the earlier version didn't manage
- Update CANNOT retro-edit the body to insert sections — that violates the skill triple invariant
- If a feature needs body structure, it belongs in setup (greenfield) or a separate file

The `Completed Steps` metadata field tracks which migrations have been applied. Idempotent — re-running update doesn't re-apply completed migrations.

## Force-All Mode

`update-rdlc force-all` skips the per-file decision step and adopts every upstream change. Surfaces a confirmation first:

> WARNING: force-all overwrites all managed files except the RDLC.md body. Customizations in `.claude/hooks/`, `scripts/`, `.claude/settings.json` will be lost.
>
> Backup will be created at `.rdlc/backup-{timestamp}/`. Continue? [y/N]

Default: N. Force-all is for new consumers who haven't customized yet.

## Check-Only Mode

`update-rdlc check-only` reports drift without prompting:

```
RDLC drift report (consumer at 0.1.0, latest 0.2.0):

MATCH:        4 files (rdlc-prompt-check.sh, ...)
CUSTOMIZED:   2 files (scripts/regression_test.sh, .claude/settings.json)
MISSING:      1 file (cli/bin/rdlc-wizard.js — new in 0.2.0)
DRIFT:        0 files

Run /update-rdlc without check-only to apply selectively.
```

No mutations. Useful in CI to detect when a consumer falls behind.

## Anti-Patterns

- **Auto-applying without diff.** Per skill triple invariant: never auto-apply without showing the delta first (unless force-all).
- **Editing the RDLC.md body.** Update only touches metadata. Body content is consumer-owned.
- **Bumping version mid-flow.** If update aborts, version stays at pre-update value. Idempotent retry.
- **Treating CLI install drift as a project-file issue.** CLI bumps and project-file updates are separate concerns; Step 2 handles CLI, Step 4-7 handles project files.
