# Open-source README Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repository understandable and installable from GitHub, with clear Codex skill and MultiAgentor CLI setup instructions.

**Architecture:** Keep the English README as the default GitHub landing page and provide a complete Simplified Chinese counterpart. Document Codex skill installation separately from MultiAgentor CLI installation so users understand that the skill supplies agent guidance while the CLI performs the automation work.

**Tech Stack:** Markdown, Codex skills, PowerShell, npm, GitHub.

---

### Task 1: Create the English project landing page

**Files:**
- Create: `README.md`

- [x] **Step 1: Explain the project and its scope**

Describe the assistant skill, supported workflows, repository layout, prerequisites, and the distinction between the skill and CLI.

- [x] **Step 2: Add Codex installation paths**

Document installation through Codex's built-in `$skill-installer` and manual installation into `$CODEX_HOME/skills` (or `~/.codex/skills`).

- [x] **Step 3: Add verification and usage examples**

Include a file-level verification command and natural-language prompts that should trigger the skill.

- [x] **Step 4: Add maintenance, contribution, and license guidance**

Document updating, uninstalling, security expectations, contribution checks, and the repository's MIT license.

### Task 2: Create the Simplified Chinese landing page

**Files:**
- Create: `README.zh-CN.md`

- [x] **Step 1: Provide a complete Chinese version**

Mirror the English document's structure and commands, using natural Chinese rather than a shortened summary.

- [x] **Step 2: Cross-link both languages**

Add language links at the top of both README files.

### Task 3: Verify the documentation

**Files:**
- Verify: `README.md`
- Verify: `README.zh-CN.md`
- Verify: `skills/multiagentor-cli-assistant/SKILL.md`

- [x] **Step 1: Check repository-relative links**

Run a local Markdown link scan and confirm every relative target exists.

- [x] **Step 2: Check documented commands against skill sources**

Compare Node.js requirements, npm commands, skill name, paths, and first-run behavior with `SKILL.md` and `references/command-reference.md`.

- [x] **Step 3: Review the Git diff**

Run `git diff --check` and inspect `git status --short` to confirm no unrelated files were changed.
