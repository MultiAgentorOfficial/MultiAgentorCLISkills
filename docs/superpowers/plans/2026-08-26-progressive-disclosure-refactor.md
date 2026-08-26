# MultiAgentor Skill Progressive Disclosure Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce the automatically loaded MultiAgentor entrypoint while preserving every operational and safety invariant through explicit, intent-based reference routing.

**Architecture:** `SKILL.md` becomes a compact router containing only shared startup rules, intent mapping, universal invariants, and reference links. Installation, browser, task, run-supervision, and troubleshooting guidance move into focused references; `command-reference.md` retains only concrete command shapes and cross-links to the workflow references.

**Tech Stack:** Markdown Codex skills, YAML UI metadata, JSON behavioral evals, Python `quick_validate.py`, Git.

---

### Task 1: Split workflow guidance by responsibility

**Files:**
- Create: `skills/multiagentor/references/installation-and-updates.md`
- Create: `skills/multiagentor/references/browser-workflows.md`
- Create: `skills/multiagentor/references/task-workflows.md`
- Create: `skills/multiagentor/references/run-supervision.md`
- Create: `skills/multiagentor/references/troubleshooting.md`

- [ ] **Step 1: Move installation and runtime-readiness rules**

Preserve version gates, npm/portable provenance, platform checks, launcher requirements, browser/runtime preparation, checksums, and script-core compatibility in `installation-and-updates.md`.

- [ ] **Step 2: Move browser-state workflows**

Preserve browser discovery/creation, proxy selection, Cookie import, fixed Profile reuse, manual launch waiting, and Windows system-proxy chaining in `browser-workflows.md`.

- [ ] **Step 3: Move task construction workflows**

Preserve script discovery, parameter choices, remote task CRUD, batch stop-on-error semantics, incompatible pure-local task migration, and command construction in `task-workflows.md`.

- [ ] **Step 4: Move supervision and result rules**

Preserve default wait behavior, run monitoring, terminal-state detection, artifact reading, result summaries, and repeat-run prompts in `run-supervision.md`.

- [ ] **Step 5: Move diagnostics and mutation safety**

Preserve failure classification, clean-machine launcher diagnosis, macOS security checks, secret redaction, rerun safety, and destructive-action confirmations in `troubleshooting.md`.

### Task 2: Convert the entrypoint into a router

**Files:**
- Modify: `skills/multiagentor/SKILL.md`
- Modify: `skills/multiagentor/references/command-reference.md`

- [ ] **Step 1: Retain only shared entrypoint rules**

Keep frontmatter, update-before-work, the login/browser/script/task/run order, live-help authority, user choice requirements, supervision default, sensitive-data handling, and the intent router.

- [ ] **Step 2: Add explicit conditional reference reads**

For every intent, name exactly which reference must be read and state that unrelated references should not be loaded.

- [ ] **Step 3: Reduce the command reference**

Keep concrete command forms and terse semantics only; link workflow explanations to the focused references and remove duplicated prose.

### Task 3: Update package metadata and behavioral coverage

**Files:**
- Modify: `skills/multiagentor/VERSION`
- Modify: `skills/multiagentor/agents/openai.yaml`
- Modify: `skills/multiagentor/evals/evals.json`
- Modify: `README.md`
- Modify: `README.zh-CN.md`

- [ ] **Step 1: Bump the Skill version**

Set `VERSION` to `1.5.0` because the instruction architecture changes while user-facing capabilities remain compatible.

- [ ] **Step 2: Keep UI metadata aligned**

Describe intent-routed browser, remote-task, and supervised-execution workflows without listing implementation detail.

- [ ] **Step 3: Add a routing eval**

Add a behavioral case requiring the Agent to load only the reference relevant to a browser-manual-launch request and preserve wait behavior.

- [ ] **Step 4: Document progressive disclosure**

Update both READMEs with the focused reference layout and explain that the entrypoint no longer loads the entire command catalog.

### Task 4: Validate structure and invariants

**Files:**
- Test: `skills/multiagentor/SKILL.md`
- Test: `skills/multiagentor/references/*.md`
- Test: `skills/multiagentor/evals/evals.json`

- [ ] **Step 1: Run structural validation**

Run:

```powershell
$env:PYTHONUTF8='1'
python C:\Users\WangChen\.codex\skills\.system\skill-creator\scripts\quick_validate.py skills\multiagentor
```

Expected: `Skill is valid!`

- [ ] **Step 2: Validate eval JSON and links**

Parse `evals.json`, verify every reference linked from `SKILL.md` exists, and confirm each reference is reachable from the entrypoint.

- [ ] **Step 3: Enforce entrypoint size target**

Measure `SKILL.md`; require at most 180 lines and 18,000 characters, with no loss of universal safety invariants.

- [ ] **Step 4: Check obsolete duplication and diff health**

Run `rg` checks for duplicated full workflows in `SKILL.md`, then `git diff --check`. Expected: no stale monolithic routing instruction and no whitespace errors.
