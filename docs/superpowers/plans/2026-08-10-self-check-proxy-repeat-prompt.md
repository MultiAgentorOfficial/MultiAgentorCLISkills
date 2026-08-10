# MultiAgentor Self-Check, Proxy Choice, and Repeat Prompt Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Skill self-check/repair, require an explicit proxy decision when creating browser environments, and emit a safe reusable prompt after every waited task run.

**Architecture:** Extend the existing version updater to validate local critical files and repair standalone installations even when SemVer is unchanged. Keep proxy behavior driven by live CLI help because current `quick-create` disables proxy. Generate repetition prompts from stable task identity and effective non-secret parameters, never transient run state.

**Tech Stack:** Markdown skill instructions, PowerShell, POSIX shell, JSON evals, live MultiAgentor CLI help.

---

### Task 1: Complete self-check and repair

- [ ] Validate `VERSION`, skill identity, command reference, UI metadata, and OS updater scripts before comparing versions.
- [ ] Treat missing/invalid critical files as repair-required for standalone installs.
- [ ] Preserve dirty Git worktrees and report rather than overwrite.
- [ ] Return `integrity_ok`, update status, versions, method, backup, and restart requirement in JSON.

### Task 2: Add proxy choice to environment creation

- [ ] Inspect live `browser quick-create --help` before presenting proxy behavior.
- [ ] Always ask whether a newly created browser should use a proxy.
- [ ] Use `quick-create` only for no-proxy creation while current help says it disables proxy.
- [ ] For proxy choice, offer an existing proxy-configured environment or guide external platform creation, then rediscover the browser ID.
- [ ] Never log or repeat proxy credentials.

### Task 3: Produce a repeat-run prompt

- [ ] After terminal state and result collection, emit one copyable natural-language prompt.
- [ ] Include stable task ID/name, saved/default versus one-run context mode, non-secret effective parameters, wait/supervision, and result collection.
- [ ] Exclude run IDs, tokens, proxy credentials, ephemeral logs, and secrets; replace required secrets with an instruction to ask again.
- [ ] Add duplicate-side-effect confirmation language where relevant.

### Task 4: Validate

- [ ] Increment Skill SemVer.
- [ ] Update README, command reference, UI metadata, and evals.
- [ ] Run skill validation, PowerShell/shell syntax checks, JSON parse, LF check, and `git diff --check`.
