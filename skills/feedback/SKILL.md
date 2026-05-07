---
name: feedback-rdlc
description: Submit feedback, bug reports, feature requests, or share RDLC patterns you've discovered. Privacy-first — always asks before scanning.
argument-hint: [optional: bug | feature | pattern | improvement | earned-rule]
effort: medium
---
# Feedback — Community Contribution Loop

## Task
$ARGUMENTS

## Purpose

Help users contribute back to claude-rdlc-wizard: bug reports, feature requests, pattern sharing, RDLC workflow improvements, and earned-rule candidates from real research projects.

## Body Invariant (Skill Triple Pattern)

This skill never writes to the consumer's `RDLC.md` at all. It writes to a single append-only log at `.rdlc/feedback-log.md` for traceability, and otherwise files issues upstream via `gh`. The consumer's research files, evidence, and deliverables are never read or transmitted without explicit per-field consent.

## Privacy & Permission (MANDATORY)

**NEVER scan the user's repo without explicit consent.** Always ask first:

> I can scan your RDLC setup to identify what you've customized vs wizard defaults. This helps me create a more specific report.
>
> May I scan? Only the following are read:
> - `RDLC.md` metadata + section headers (NOT body content)
> - `.claude/hooks/` file names + active hook list
> - `.claude/skills/` skill names
> - `.claude/settings.json` hook configuration (NOT permissions, NOT secrets)
> - `scripts/regression_test.sh` line count + assertion count (NOT assertion content)
> - `.rdlc/version` and `.rdlc/slop-allowlist.txt` line count (NOT entries — they may contain proper nouns from your domain)

**What is NEVER scanned:**

- Source content (research files, evidence, deliverables)
- `.env`, secrets, credentials, API keys
- Citations, sources, URLs (they identify the research domain)
- Slop allowlist entries (proper nouns identify the project)
- Git history, commit messages
- Memory namespace contents

## Privacy Allowlist (per skill-triple-pattern.md)

Auto-context fields in the issue body are classified:

**AUTO** (attached without prompting — non-identifying):
- Wizard version (from RDLC.md metadata)
- Setup date
- OS / Claude Code version
- Hook count, skill count, regression assertion count
- Has-codex-installed (yes/no)
- Has-sdlc-wizard-paired (yes/no)

**CONFIRM** (per-field explicit confirm at preview; defaults REDACTED if declined):
- Project name (from package.json or directory name)
- Detected domain preset (medical-legal / political-research / automotive-audit / general)
- Hook customization summary (which hooks are modified)

**EXCLUDED** (never auto-attach, even with consent):
- Source citations
- Allowlist entries
- Research file names or counts
- Memory contents
- Git remote URL

## Feedback Types

### Bug Report

1. Ask user to describe the issue
2. With permission, check installed wizard version and confirm OS/CC version
3. Check if hooks are properly configured (file presence, executable bit, settings.json registration)
4. Create a GitHub issue with reproduction steps and AUTO + confirmed CONFIRM fields

### Feature Request

1. Ask user what they want
2. With permission, check if a similar capability already exists in their setup
3. Create issue with the request and context

### Pattern Sharing

1. Ask user what pattern they've discovered (custom hook, modified philosophy, test approach, source-tier extension, audience-firewall variant)
2. With permission, diff their RDLC setup against wizard defaults to identify customizations
3. Ask which customizations worked well and why
4. Create issue describing the pattern, evidence, and which case study (if any) it generalizes

### RDLC Workflow Improvement

1. Ask what could be better about the RDLC workflow
2. With permission, check which RDLC steps they use most/least
3. Create issue with the improvement suggestion

### Earned-Rule Candidate

This is the load-bearing feedback type for graduation. When a consumer earns a new rule through real research work, that's a candidate for promotion to the wizard playbook.

1. Ask user to describe the earned rule (situation, what they did, what they would have wished the wizard told them)
2. Ask which case study it most resembles (anticheat / states-project / tucson / new domain)
3. With permission, check if the rule already exists in `RDLC.md` "Lessons Learned" or in the wizard repo's `CASE_STUDIES.md`
4. Create issue tagged `earned-rule-candidate` for playbook author review

## Creating the Issue

Use `gh issue create` on the wizard repo:

```bash
gh issue create \
  --repo BaseInfinity/claude-rdlc-wizard \
  --title "[feedback-type]: Brief description" \
  --label "$LABEL" \
  --body "$(cat <<'EOF'
## Feedback Type
bug / feature / pattern / improvement / earned-rule

## Description
[User's description]

## Context (AUTO fields)
- Wizard version: [from RDLC.md metadata]
- Setup date: [from RDLC.md metadata]
- Domain preset: [confirmed]
- Hook count: [scan]
- Regression assertion count: [scan]
- Codex installed: [yes/no]
- Paired with claude-sdlc-wizard: [yes/no]

## Customizations (if pattern sharing, with consent)
[Diff summary against wizard defaults]

## Evidence (for earned-rule)
[What the user customized and why it worked. Which case study it resembles.]

---
Submitted via `/feedback-rdlc` skill
EOF
)"
```

Label table:

| Type | Label |
|------|-------|
| bug | bug |
| feature | enhancement |
| pattern | pattern-share |
| improvement | improvement |
| earned-rule | earned-rule-candidate |

## Race-Check Discipline

Between scan (Step 2) and `gh issue create` (Step 5), another skill (update-rdlc) could have changed metadata. Compute a hash of the RDLC.md metadata header at scan time, reread + recompare before filing. Mismatch aborts filing; draft fields preserved in `.rdlc/feedback-draft-{timestamp}.md` for recovery.

## No Credential Handling

Delegate auth entirely to `gh` CLI. The skill never reads, stores, or transmits tokens.

Account-mismatch warning: before filing, run `gh api user --jq .login` to confirm the authenticated GitHub user. If the user's local git config (`git config user.email`) doesn't match a known maintainer email, surface:

> You're authenticated as @githubuser, filing to BaseInfinity/claude-rdlc-wizard. Continue? [y/N]

Catches "filed from wrong account" without any credential code.

## No Local Fallback

If upstream filing fails (gh auth missing, repo archived, network down), stop and print the issue body for manual submission:

> Could not file upstream (reason: [error]).
>
> Copy the body below and submit manually at https://github.com/BaseInfinity/claude-rdlc-wizard/issues/new
>
> [body]

Do NOT fall back to filing in the consumer's own repo — that defeats the upstream-loop purpose.

## Append-Only Local Log

After successful filing, append to `.rdlc/feedback-log.md`:

```markdown
## YYYY-MM-DD — [feedback-type]: brief title

- Issue: [URL]
- Type: bug | feature | pattern | improvement | earned-rule
- Wizard version at submission: X.Y.Z
- Status: filed
```

This file is consumer-owned, never edited by the wizard after creation. Tracks the submission history without re-reading upstream.

## Rules

- **Privacy first** — always ask before scanning anything
- **Opt-in only** — if user declines scan, still create the issue with whatever they tell you manually
- **No source content** — never include research content, citations, or allowlist entries
- **Be specific** — vague issues waste maintainer time; ask clarifying questions
- **Check for duplicates** — `gh issue list --repo BaseInfinity/claude-rdlc-wizard --search "keywords"` before creating
- **Race-check** — re-verify metadata immediately before filing
- **Account-check** — confirm authenticated GitHub user before filing
