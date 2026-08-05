# MultiAgentor Version Auto-Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Detect and automatically install newer MultiAgentor skill and npm CLI releases before starting an automation workflow.

**Architecture:** Give the skill an independent SemVer `VERSION` file and OS-specific self-updaters that compare it with the official GitHub repository. Keep CLI version resolution tied to npm's `latest` dist-tag and update only npm-managed installations; preserve bundles and explicit custom executables.

**Tech Stack:** PowerShell, POSIX shell, Git/GitHub archive downloads, npm registry, Markdown skill instructions.

---

### Task 1: Version the skill

**Files:**
- Create: `skills/multiagentor/VERSION`
- Modify: `skills/multiagentor/SKILL.md`

- [ ] Add a strict SemVer version file.
- [ ] Require one update check at the beginning of each new MultiAgentor workflow.
- [ ] Stop and request a new Codex/WorkBuddy task after replacing the loaded skill.

### Task 2: Implement skill self-update

**Files:**
- Create: `skills/multiagentor/scripts/update-skill.ps1`
- Create: `skills/multiagentor/scripts/update-skill.sh`

- [ ] Read the local and official GitHub `VERSION` values.
- [ ] Return without mutation when the installed version is current.
- [ ] Use `git pull --ff-only` only for a clean Git worktree.
- [ ] For standalone installations, download the official repository archive, validate its skill identity/version, stage it beside the installation, replace atomically, retain a backup, and roll back on failure.
- [ ] Emit one JSON summary containing old/new versions and whether a new task is required.

### Task 3: Implement CLI update checks

**Files:**
- Modify: `skills/multiagentor/scripts/bootstrap-portable-cli.ps1`
- Modify: `skills/multiagentor/scripts/bootstrap-portable-cli.sh`
- Modify: `skills/multiagentor/references/command-reference.md`

- [ ] Compare the installed npm package version with `npm view multiagentor-cli@latest version`.
- [ ] Upgrade portable/global npm installations when versions differ and verify the installed version plus `--help`.
- [ ] Do not overwrite full bundles or custom executors.

### Task 4: Document and validate

**Files:**
- Modify: `README.md`
- Modify: `README.zh-CN.md`
- Modify: `skills/multiagentor/evals/evals.json`
- Modify: `skills/multiagentor/agents/openai.yaml`

- [ ] Document version ownership, automatic update behavior, backup/rollback, and restart requirements.
- [ ] Add evaluation coverage for outdated skill and CLI installations.
- [ ] Validate PowerShell/shell syntax, JSON, SemVer, skill structure, line endings, and `git diff --check`.
