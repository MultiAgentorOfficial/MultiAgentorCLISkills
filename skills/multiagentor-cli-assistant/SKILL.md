---
name: multiagentor-cli-assistant
description: Install, guide, and operate MultiAgentor CLI on Windows through its npm package for login, script discovery, browser environment creation, remote task CRUD, local task execution, logs, cancellation, and configuration. Use this skill whenever a user asks how to install or use multiagentor-cli, wants to run an RPA automation even when the CLI is not installed yet, provides only a partial operation or parameters, needs help choosing a script/browser/task, or reports a CLI/run failure. Bootstrap and verify the CLI first, proactively discover live candidates, infer safe defaults, and ask focused choice-based follow-up questions instead of making the user memorize commands, flags, or IDs.
---

# MultiAgentor CLI Assistant

Turn the user's goal into a valid MultiAgentor CLI workflow. Reduce cognitive load: discover what can be discovered, recommend a choice with a reason, and only ask about information that cannot be inferred safely.

## Start here

1. Restate the intended outcome in one short sentence.
2. Bootstrap the CLI before API discovery. Prefer the published npm package when no trusted project bundle is already in scope; follow **Install or select the CLI** below.
3. Run the selected invocation with `--help` and treat live help as authoritative.
4. Use read-only discovery commands before asking the user for IDs or supported values.
5. Build a parameter state table internally: known, discovered, safely defaulted, missing, ambiguous, or consequential.
6. Ask only about missing, ambiguous, or consequential values, except that task creation always includes an explicit user choice about the selected script's execution parameters. Continue automatically after the answer when the requested action authorizes it.

Read [references/command-reference.md](references/command-reference.md) when assembling a command or diagnosing behavior.

## Install or select the CLI

Resolve one stable invocation and reuse it for the entire workflow.

1. If the user supplied a project bundle containing `multiagentor-cli.cmd`, use that launcher, especially for local runs. Do not download a duplicate CLI merely because the command is not global.
2. Otherwise test `Get-Command multiagentor-cli -ErrorAction SilentlyContinue`.
3. If the command is absent, first verify `node --version` and `npm --version`; require Node.js 18 or newer.
4. Prefer installing the current npm release for a reusable workflow:

   ```powershell
   npm.cmd install --global multiagentor-cli@latest
   multiagentor-cli --help
   ```

5. If global installation is unavailable because of permissions or PATH, fall back to the non-interactive npm launcher and use the full prefix for every later command:

   ```powershell
   npx.cmd --yes multiagentor-cli@latest --help
   ```

   Invocation prefix: `npx.cmd --yes multiagentor-cli@latest`

6. Do not mix a bundled executable, global command, and npx within one workflow unless diagnosing an installation problem. This prevents config/runtime/version drift.
7. `--help`, auth, config, and remote CRUD do not download the browser. On the first npm-launched `run start` or `run execute`, allow the launcher to install the packaged RPA Agent, download the browser manifest and ZIP, verify size and SHA-256, extract atomically, and cache both under `%APPDATA%\multiagentor-cli\`. Do not interrupt this first-run preparation.
8. Reuse the cached verified browser on later runs. Use `MULTIAGENTOR_BROWSER_EXECUTABLE` only when the user supplies a known compatible `ClonBrowserCore.exe`; do not substitute ordinary Chrome automatically.

Installation is an expected prerequisite when the user asks to run an RPA task and no CLI is available. Report the chosen installation method and verified invocation without dumping npm logs.

## Intent routing

Map natural-language requests to these flows:

| User goal | Flow |
| --- | --- |
| First use, login, authorization | `auth oauth` |
| Find or choose automation capability | script discovery |
| Create or choose a browser environment | browser discovery / `quick-create` |
| Create a reusable automation task | task creation |
| Run an existing task | `run start` |
| Run an already assembled task JSON | `run execute` |
| Inspect failure or progress | run list/get/log files |
| Stop work | `run cancel` |
| Remove a task or log out | destructive/account flow |

If the user's operation is unclear, offer 2-3 goal-level choices instead of asking “What do you want to do?”. Recommend the most likely one from their wording. Example:

1. 创建并运行一个新任务（推荐）— 适合只有业务目标、还没有任务 ID。
2. 运行已有任务 — 适合已经创建过任务。
3. 排查失败运行 — 适合已经有 run ID 或错误信息。

## Choice-driven heuristic

### Discover before asking

Use commands that do not mutate state to obtain real choices:

- Effective setup: `multiagentor-cli config show`
- Script categories: `multiagentor-cli --json script categories`
- Script candidates: `multiagentor-cli --json script my ...`
- Script parameters and defaults: `multiagentor-cli script execute-detail --id <id>`
- Supported systems: `multiagentor-cli --json browser systems`
- Browser candidates: `multiagentor-cli --json browser list ...`
- Task candidates: `multiagentor-cli --json task list ...`
- Local task detail: `multiagentor-cli task get --id <id> --full`
- Run candidates/detail: `multiagentor-cli --json run list ...` and `run get --run-id <id> --full`

Do not invent a candidate when discovery fails. Explain the failure briefly, then ask for the missing value or propose the smallest diagnostic command.

### Rank candidates

Rank live candidates using the user's words, in this order:

1. Exact or near-exact name match.
2. Category or description match.
3. Recently or commonly referenced candidate when that fact is present in output.
4. The simplest candidate satisfying the goal.

Show at most three candidates. Put the recommendation first and explain the match in one short sentence. Preserve exact IDs in the choices.

If there is one strong match, ask for confirmation only when selecting it causes a consequential action. If the next step is read-only, inspect it directly.

### Derive questions from parameter metadata

After selecting a script ID, always run `script execute-detail --id <scriptId>` before creating the task. Treat its `scriptContext`, README, defaults, and constraints as the source for follow-up questions. The execution parameters are user-editable, so task creation must pause and let the user choose whether to keep the defaults or provide custom values. Do not silently accept all defaults and immediately create the task.

First summarize the discovered parameters without dumping unrelated response fields. Show each exact parameter name, current/default value when non-sensitive, whether it appears required, and any documented description or constraint. Then offer:

1. 自定义填写执行参数（推荐 when the user described a specific target or behavior）— ask for values field by field or in a small related group.
2. 使用脚本默认参数（推荐 when the user expressed no customization intent）— omit both context flags.
3. 查看参数说明后再决定 — show the relevant README excerpts in a concise paraphrase, then ask again.

The recommendation depends on the user's stated goal, but the choice itself must always be presented during task creation. If `scriptContext` is empty or absent, state that the script exposes no configurable execution parameters and ask whether to continue creating the task; do not invent fields.

For each parameter:

- Keep a valid user-provided value.
- Preserve an explicit script default as the recommended value, but during task creation still show it and let the user keep or replace it.
- Ask for a required value with no usable default.
- Convert enum/allowed values into choices and recommend the default or best semantic match.
- Convert booleans into concrete effect choices such as “启用重试” / “不启用重试”, not abstract true/false when labels are known.
- For a numeric range, propose a conservative value and show the valid range.
- For paths, URLs, accounts, selectors, or free text, give 1-2 realistic examples and allow a custom answer.
- For secrets, never echo the value, place it in logs, or embed it in a reusable skill artifact. Prefer an existing secure mechanism if the script documents one.
- For an unknown field, quote its exact name and relevant README description; do not guess its semantics.

Ask related questions together only when the interface supports 1-3 short questions. Otherwise ask the highest-impact question first. Every choice set should have 2-3 mutually exclusive options, put the recommendation first, explain the tradeoff, and allow a custom value.

### Decide whether context should be overridden

The absence of context flags means “use script defaults”; `{}` means “clear defaults”. Never confuse these states.

Offer these choices when context behavior matters:

1. 使用脚本默认参数（推荐）— omit both context flags.
2. 本次自定义参数 — use `run start --script-context...`; do not alter the cached task payload.
3. 保存自定义参数到任务 — use task create/update/refresh with context so the runnable payload is refreshed locally.

On Windows PowerShell, prefer `--script-context-file` whenever creating, updating, refreshing, or running with custom context. Write the complete context as a UTF-8 JSON file, validate that its top level is an object, and pass the file path. This is the default even for short JSON because Windows PowerShell 5.1 can remove embedded double quotes while converting arguments for a native EXE. Use inline `--script-context` only when the user explicitly requires it or the shell's native-argument behavior has been verified. Send the object directly; never wrap it in `{ "context": ... }`.

## Workflow recipes

### Create and optionally run a task

1. Check authentication/config if the request or error suggests it is needed.
2. Discover scripts; use the user's business terms as `--name`, `--description`, or `--category` filters.
3. Immediately run `script execute-detail --id <scriptId>` after the script ID is chosen.
4. Present the script's configurable execution parameters and explicitly ask whether the user wants defaults, custom values, or more explanation. When custom values are chosen, resolve them from the returned metadata, merge them with the defaults that must be preserved, write the complete context to a UTF-8 JSON file, validate it, and use `--script-context-file` before continuing.
5. Discover browser environments. If none fit, inspect supported systems and offer `browser quick-create` choices.
6. Derive a short task name from the chosen script and target; ask only if naming matters to the user.
7. Use task type `local` unless live help or the user requires another supported type.
8. Show a compact summary: script, browser, task name, chosen execution parameters/context mode, and whether execution will start.
9. Creating a remote task changes state. If the user only asked for instructions or has not authorized creation, show the command and ask before running it. If they explicitly asked to create/run it, proceed after the execution-parameter choice is complete.
10. Parse the returned task ID rather than asking the user to copy it manually, then run when authorized.

### Run an existing task

1. If no task ID is given, list tasks and offer up to three matches.
2. Default to the cached payload when the user did not request a parameter override.
3. If override intent is present, inspect the task/script and resolve only changed context fields.
4. Use the resolved npm/global launcher, or the `.cmd` launcher from a supplied bundle, so the first local run can prepare the RPA Agent/browser runtime.
5. Report the run ID and the next inspection command.

### Diagnose a failed run

1. Resolve the run ID from the user's input or `run list`.
2. Read `run get --full` and lifecycle logs.
3. Use the returned `output.log_files` paths to inspect `stderr.log` and `agent.log` when needed.
4. Classify the failure before recommending a fix:
   - CLI/auth/API/configuration
   - browser runtime download or executable
   - invalid task envelope/context
   - RPA Agent process failure
   - target website/script behavior
5. Redact tokens, cookies, authorization headers, passwords, and sensitive script input in any explanation.
6. Do not rerun automatically if the run could repeat external side effects. Offer a corrected rerun choice first.

## Confirmation and safety

Read-only discovery does not need confirmation. Respect the user's explicit request as authorization for ordinary in-scope create/run/update actions.

Ask for explicit confirmation immediately before:

- `task delete`, because it deletes the remote task, local mirror, runs, and logs.
- `auth logout`, because it clears the local token.
- `run cancel`, unless the user explicitly asked to stop that run.
- `config set`, when it replaces a working endpoint, database, or executor.
- A rerun that may duplicate submissions, purchases, messages, uploads, or other external effects.

Show the exact target ID/value and consequence in the confirmation. Never print a bearer token or the token fields returned by `config show`.

## Command construction rules

- Put global `--json` before the command: `multiagentor-cli --json task list`.
- Quote PowerShell values containing spaces or special characters.
- For task create/update/refresh and context-overridden runs in Windows PowerShell, default to a UTF-8 JSON file plus `--script-context-file`; do not first attempt inline JSON and fall back only after quote corruption.
- Preserve the full `options` and `vars` structure returned by `execute-detail` when changing one field, unless the script documentation explicitly supports a partial context.
- In Windows PowerShell 5.1, prefer `--task-file <path>` over stdin for non-ASCII JSON. If stdin is required, set `$OutputEncoding = [System.Text.UTF8Encoding]::new($false)` first.
- Use `ConvertFrom-Json` when chaining a returned ID into a later PowerShell command.
- Do not use `run execute` when the user expects a remote task or local SQLite run record; it creates neither.
- Do not assume `task list` caches runnable `/cli` payloads. Use create/update/refresh for that.

## Response shape

When waiting for a user choice, keep the response short:

1. One sentence stating what was discovered.
2. A 2-3 option choice set with the recommendation first.
3. One concise question.

When ready to act or hand off, provide:

- The chosen values and defaults.
- The exact PowerShell command or the result of executing it.
- The created task/run ID when present.
- One next command for status or logs.

Avoid dumping the full command catalog unless the user asks for reference documentation.
