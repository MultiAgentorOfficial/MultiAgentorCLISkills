# MultiAgentor macOS Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the MultiAgentor skill install and operate the current npm CLI on supported Windows and Apple Silicon macOS hosts.

**Architecture:** Keep the platform-neutral workflow in `SKILL.md`, route installation to one OS-specific portable bootstrap, and keep exact shell commands and data paths in the command reference. Treat the npm package metadata and live help as authoritative so the skill does not hardcode a CLI version or assume unsupported platforms.

**Tech Stack:** Markdown skill instructions, PowerShell 5.1+, POSIX shell, Node.js/npm, npm package metadata.

---

### Task 1: Add an Apple Silicon portable bootstrap

**Files:**
- Create: `skills/multiagentor/scripts/bootstrap-portable-cli.sh`
- Modify: `skills/multiagentor/scripts/bootstrap-portable-cli.ps1`

- [ ] **Step 1: Add platform guards**

Require `Darwin arm64` in the shell bootstrap and current npm-supported Windows architecture in the PowerShell bootstrap. Fail with the detected platform instead of attempting an incompatible installation.

- [ ] **Step 2: Install a verified portable Node.js runtime**

Select the newest Node.js LTS release >=18 that publishes the matching archive, download it from `nodejs.org`, and verify the archive against `SHASUMS256.txt` before extraction.

- [ ] **Step 3: Install and verify the current CLI**

Install `multiagentor-cli@latest` into an isolated user cache, generate an OS-native launcher, run `--help`, and print a reusable JSON invocation without changing the machine-wide PATH.

- [ ] **Step 4: Test script syntax and safety gates**

Run:

```bash
sh -n skills/multiagentor/scripts/bootstrap-portable-cli.sh
```

Expected: exit code 0. On Windows, invoke the shell script and expect an explicit `macOS only` failure before any download.

### Task 2: Make the skill platform-aware

**Files:**
- Modify: `skills/multiagentor/SKILL.md`
- Modify: `skills/multiagentor/references/command-reference.md`

- [ ] **Step 1: Document supported platform discovery**

Require the agent to inspect OS and CPU architecture first. Support `win32-x64` and `darwin-arm64` only when those keys are present in the installed npm package; stop clearly on Intel macOS or another missing platform key.

- [ ] **Step 2: Route launchers and caches by OS**

Use `.cmd`/PowerShell and `%APPDATA%\multiagentor` on Windows; use the npm shell shim/POSIX shell and `~/Library/Application Support/multiagentor` on macOS.

- [ ] **Step 3: Update runtime-readiness terminology**

Describe the current packaged `multi-agentor-script-core`, `MULTIAGENTOR_SCRIPT_CORE_COMMAND`, platform browser artifact, native browser executable, checksum verification, executable permissions, and launcher-only execution path.

- [ ] **Step 4: Keep execution and result supervision platform-neutral**

Retain foreground/background monitoring, terminal-state polling, and result collection rules while giving both Windows and macOS log roots.

### Task 3: Update user documentation and evaluations

**Files:**
- Modify: `README.md`
- Modify: `README.zh-CN.md`
- Modify: `skills/multiagentor/evals/evals.json`
- Modify: `skills/multiagentor/agents/openai.yaml`

- [ ] **Step 1: Add macOS install examples**

Document Codex manual installation, npm/npx use, portable bootstrap behavior, Apple Silicon support, and the first-run browser download path.

- [ ] **Step 2: Add a clean-mac evaluation**

Require the skill to reject Intel macOS, bootstrap Node/npm on Apple Silicon when absent, retain the JavaScript launcher, wait through runtime preparation, and supervise the run through result collection.

- [ ] **Step 3: Refresh UI metadata**

Mention Windows and Apple Silicon macOS without embedding a CLI version.

- [ ] **Step 4: Validate the finished skill**

Run the skill validator, JSON parsing, shell syntax check, `git diff --check`, and scans for obsolete Agent/browser names and Windows-only claims. Expected: all checks pass; any unavailable validator dependency is reported separately.
