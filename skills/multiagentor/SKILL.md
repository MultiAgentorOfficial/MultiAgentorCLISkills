---
name: multiagentor
description: "Install, guide, and operate MultiAgentor CLI on Windows through its npm package for login, browser environment selection or creation, personal and market script discovery, remote task CRUD, local task execution, logs, cancellation, and configuration. Use this skill whenever a user asks how to install or use multiagentor-cli, wants to browse or run an RPA automation even when the CLI is not installed yet, provides only a partial operation or parameters, needs help choosing a browser/script/task, or reports a CLI/run failure. For new automations, guide the user in this order: authenticate, choose or create a browser environment, search personal scripts with a market fallback, choose script parameters, create a task, then run it. Bootstrap and verify the CLI first, proactively discover live candidates, infer safe defaults, and ask focused choice-based follow-up questions instead of making the user memorize commands, flags, or IDs."
---

# MultiAgentor

Turn the user's goal into a valid MultiAgentor CLI workflow. Reduce cognitive load: discover what can be discovered, recommend a choice with a reason, and only ask about information that cannot be inferred safely.

## Start here

1. Restate the intended outcome in one short sentence.
2. Bootstrap the CLI before API discovery. Prefer the published npm package when no trusted project bundle is already in scope; follow **Install or select the CLI** below.
3. Run the selected invocation with `--help` and treat live help as authoritative.
4. Authenticate before protected discovery. Run `auth oauth` when login is requested, no usable token exists, or a discovery command reports an authentication failure; wait for successful authorization before continuing.
5. For a new automation, preserve this order: **login → choose/create browser environment → choose script and execution parameters → create task → run task**. Do not select the script before resolving the browser environment.
6. Use read-only discovery commands before asking the user for IDs or supported values.
7. Build a parameter state table internally: known, discovered, safely defaulted, missing, ambiguous, or consequential.
8. Ask only about missing, ambiguous, or consequential values, except that browser mode selection and task execution parameters are explicit user choices for every new task. Continue automatically after the answer when the requested action authorizes it.

Read [references/command-reference.md](references/command-reference.md) when assembling a command or diagnosing behavior.

## Install or select the CLI

Resolve one stable invocation and reuse it for the entire workflow.

1. Classify a user-supplied artifact before choosing an entry point:
   - An npm installation or extracted npm `.tgz` contains `bin\multiagentor-cli.js` and `dist\multiagentor-cli.exe`. Invoke only the npm-generated `multiagentor-cli.cmd`, `npx`, or the skill-generated portable launcher. Never invoke `dist\multiagentor-cli.exe` directly: doing so bypasses browser preparation and omits `MULTIAGENTOR_BROWSER_EXECUTABLE` on a clean machine. If only a `.tgz` was supplied, install it with npm instead of treating `dist\multiagentor-cli.exe` as standalone.
   - A full Windows bundle contains a root `multiagentor-cli.cmd`, `runtime\server-rpa-agent.exe`, and `browsers\...\ClonBrowserCore.exe`. Verify those paths and use the root `.cmd`; it supplies the bundled runtime paths and does not need npm to download a browser.
   Do not download a duplicate CLI merely because a valid launcher is not global.
2. Otherwise test `Get-Command multiagentor-cli -ErrorAction SilentlyContinue`.
3. If the command is absent, check `node --version` and `npm --version`; require Node.js 18 or newer.
4. If Node.js/npm is missing, Node.js is older than 18, or neither command is usable, run the bundled [portable bootstrap script](scripts/bootstrap-portable-cli.ps1). It selects the latest compatible Node.js LTS ZIP for Windows x64/ARM64 from `nodejs.org`, verifies the official SHA-256 checksum, extracts it atomically under `%APPDATA%\multiagentor-cli\portable-runtime`, installs `multiagentor-cli@latest` into the same isolated cache, verifies `--help`, and returns JSON containing a reusable `invocation` path:

   ```powershell
   $runtime = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bootstrap-portable-cli.ps1 |
       Select-Object -Last 1 |
       ConvertFrom-Json
   & $runtime.invocation --help
   ```

   Resolve the script path relative to this installed skill, not the user's current directory. Reuse the returned `invocation` for the entire workflow. Do not modify the machine-wide PATH or install system-wide Node.js. Network/sandbox approval may still be required by the active environment; request it when the tool reports that requirement. Report the official download source, selected version/platform, cache path, and checksum result without dumping npm logs.
5. If compatible Node.js/npm is already available, prefer installing the current npm release for a reusable workflow:

   ```powershell
   npm.cmd install --global multiagentor-cli@latest
   multiagentor-cli --help
   ```

6. If global installation is unavailable because of permissions or PATH, fall back to the non-interactive npm launcher and use the full prefix for every later command:

   ```powershell
   npx.cmd --yes multiagentor-cli@latest --help
   ```

   Invocation prefix: `npx.cmd --yes multiagentor-cli@latest`

7. Do not mix a full-bundle launcher, portable launcher, global npm shim, npx, or a package-internal executable within one workflow unless diagnosing an installation problem. Never shorten a resolved npm/portable invocation to the Go executable path. This prevents both runtime bypass and config/version drift.
8. `--help`, auth, config, and remote CRUD do not download the browser. On the first npm-launched `run start` or `run execute`, allow the JavaScript launcher to install the packaged RPA Agent, download the browser manifest and ZIP, verify size and SHA-256, extract atomically, set both `MULTIAGENTOR_AGENT_COMMAND` and `MULTIAGENTOR_BROWSER_EXECUTABLE`, and only then start the Go CLI. Do not interrupt this first-run preparation.
9. Reuse the cached verified browser on later runs. Use `MULTIAGENTOR_BROWSER_EXECUTABLE` only when the user supplies a known compatible `ClonBrowserCore.exe`; do not substitute ordinary Chrome automatically.

Installation is an expected prerequisite when the user asks to run an RPA task and no CLI is available. Report the chosen installation method and verified invocation without dumping npm logs.

### Enforce the runtime-readiness gate

Treat npm installation and local runtime readiness as separate states. `npm install` alone is not proof that a task can run. For every npm/portable `run start` or `run execute`, preserve the installed package's JavaScript launcher as a blocking readiness gate before the Go CLI:

1. Confirm Node.js 18+, the selected npm/portable launcher, `bin\multiagentor-cli.js`, `dist\multiagentor-cli.exe`, the packaged `server-rpa-agent.exe`, and `agent-manifest.json` exist. If the installed npm package is incomplete, repair/reinstall it before attempting the task.
2. Let the launcher install the packaged Agent into its versioned `%APPDATA%\multiagentor-cli\runtime\` directory and validate it using the packaged manifest and declared size.
3. Let it resolve `MULTIAGENTOR_BROWSER_EXECUTABLE`: honor a user-supplied compatible executable only if the path exists; otherwise fetch and validate the configured HTTPS browser manifest, download the versioned ZIP when no valid cache exists, verify declared size and SHA-256, extract atomically, confirm the declared `ClonBrowserCore.exe` exists, and update the cache pointer.
4. Require both resolved Agent and browser paths. The launcher must set `MULTIAGENTOR_AGENT_COMMAND` and `MULTIAGENTOR_BROWSER_EXECUTABLE` before it spawns the Go CLI. Do not manually start the Go CLI while preparation is pending.
5. If any readiness step fails, stop before task execution, report the failed preparation stage, and offer retry/repair. Do not describe the task as running, do not create a replacement task, and do not fall back to the raw EXE.

Check live help before assuming a separate runtime-preparation command exists. When none is exposed, treat the readiness gate as the blocking prefix of the first correctly launched `run start` or `run execute`; wait through it and distinguish its preparation messages from task progress. Later runs may reuse a valid cached browser according to the installed launcher's documented cache/fallback behavior.

## Intent routing

Map natural-language requests to these flows:

| User goal | Flow |
| --- | --- |
| First use, login, authorization | `auth oauth` |
| Create and run a new automation | login → browser choice → script choice → task creation → `run start` |
| Browse the full script market | `script list` |
| Choose a script for task execution | `script my`, then `script list` when no suitable personal result exists |
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
- Personal script candidates: `multiagentor-cli --json script my ...`
- Full script-market fallback: `multiagentor-cli --json script list ...`
- Script parameters and defaults: `multiagentor-cli script execute-detail --id <id>`
- Supported systems: `multiagentor-cli --json browser systems`
- Browser candidates: `multiagentor-cli --json browser list ...`
- Task candidates: `multiagentor-cli --json task list ...`
- Local task detail: `multiagentor-cli task get --id <id> --full`
- Run candidates/detail: `multiagentor-cli --json run list ...` and `run get --run-id <id> --full`

Do not invent a candidate when discovery fails. Explain the failure briefly, then ask for the missing value or propose the smallest diagnostic command.

### Search personal scripts, then fall back to the market

Treat the script commands exposed by current live help as different scopes:

- Use `--json script my` first when selecting a script for task creation; it searches scripts associated with the authenticated user.
- If `script my` returns no suitable match, automatically repeat the search with `--json script list` against the full market. Tell the user that personal results were empty before presenting market candidates.
- Use `--json script list` directly when the user explicitly asks to browse the whole market.
- Use `--json script categories` to discover valid category labels for either search.
- Allow the user to select a market result and continue to `execute-detail` and task creation; do not require it to also appear in `script my`. Treat an actual permission or availability error from the server as authoritative, then explain the failure and offer other personal or market candidates.

### Preserve guided choice points

For a new task, use this interaction loop at every material decision: **discover → summarize → recommend → ask → act → report**. Do not collapse the whole workflow into an uninterrupted series of mutations merely because defaults exist.

Always give the user a correction or selection opportunity at these checkpoints:

1. After login: use an existing browser environment or create a new one.
2. Browser resolution: choose the existing browser, or choose the name/OS/version for creation.
3. Script resolution: choose from at most three ranked real scripts.
4. Script parameters: use defaults, customize values, or view explanations.
5. Final task summary: create and run now, create without running, or return to modify the browser/script/parameters.

Put the recommended option first and explain its effect in one sentence. Preserve exact IDs but pair them with human-readable names. Do not ask for values that discovery can provide, repeat a decision the user already made explicitly, or add confirmation to read-only commands. Destructive actions still follow the stricter confirmation rules below.

### Choose a browser environment before scripts

For every new task, resolve the browser immediately after authentication and before script discovery:

1. Run `--json browser list` to discover existing environments.
2. If one or more environments exist, explicitly offer:
   1. 使用已有浏览器环境（推荐 when a suitable match exists）— show at most three ranked environments with exact IDs.
   2. 创建新的浏览器环境 — inspect `--json browser systems`, then offer valid OS/version choices.
3. If no environments exist, state that clearly, run `--json browser systems`, and guide the user to create one with `browser quick-create`. Do not ask the user to provide a browser ID that does not exist, and do not proceed to script selection until creation succeeds.
4. Derive a short browser name from the target/OS when naming is unimportant; ask only when the user wants a specific name. `quick-create` changes remote state, so show the chosen name, OS, and version immediately before executing it unless the user's request already authorized creation.
5. Parse the selected or newly created browser ID and retain it for task creation. Never invent an ID.

If the user supplied a browser ID, confirm it appears in discovery results and treat the browser step as resolved. Running an existing task does not require this choice because its cached payload already identifies the browser and script.

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

1. Verify the CLI invocation, then authenticate with `auth oauth` when needed. Do not continue protected discovery until login succeeds.
2. Run `--json browser list` and explicitly ask whether to use an existing environment or create a new one when existing environments are available.
3. If the user chooses creation or the list is empty, run `--json browser systems`, resolve a valid name/OS/version choice, execute `browser quick-create`, and parse the new browser ID.
4. Discover scripts only after the browser ID is resolved. Search `--json script my` first with the user's business terms as `--name`, `--description`, or `--category` filters; when it has no suitable result, search `--json script list` with the same filters and present market candidates. Do not require a selected market script to appear in both results.
5. Immediately run `script execute-detail --id <scriptId>` after the script ID is chosen.
6. Present the script's configurable execution parameters and explicitly ask whether the user wants defaults, custom values, or more explanation. When custom values are chosen, resolve them from the returned metadata, merge them with the defaults that must be preserved, write the complete context to a UTF-8 JSON file, validate it, and use `--script-context-file` before continuing.
7. Derive a short task name from the chosen script and target; ask only if naming matters to the user.
8. Use task type `local` unless live help or the user requires another supported type.
9. Show a compact summary: browser, script, task name, chosen execution parameters/context mode, and proposed execution behavior.
10. Offer a final choice: 创建并立即运行（recommended when the user asked to run）、仅创建任务、返回修改选择. This is the correction checkpoint before task creation; do not create until it is resolved.
11. Create the task when chosen and parse the returned task ID rather than asking the user to copy it manually.
12. Run the new task with `run start --task-id <taskId>` only when the user chose immediate execution, then report the run ID and next status/log command. If the user chose create-only, report the task ID and the exact later run command.

### Run an existing task

1. If no task ID is given, list tasks and offer up to three matches.
2. Default to the cached payload when the user did not request a parameter override.
3. If override intent is present, inspect the task/script and resolve only changed context fields.
4. Use the exact resolved full-bundle, portable, npm-shim, or npx invocation. Before a local run on a clean machine, confirm it does not target `dist\multiagentor-cli.exe` or another raw Go executable. Apply the **runtime-readiness gate**; the npm/portable JavaScript launcher must remain in the call chain and must finish preparing the Agent/browser and injecting both paths before the Go CLI may execute the task.
5. Treat runtime preparation output as the blocking prefix of the same first run. If it fails, stop and report a preparation failure rather than a task/script failure; if it succeeds, continue waiting for the actual task result.
6. Report the run ID and the next inspection command.

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
5. For a browser-executable failure at 0% on a clean machine, inspect launcher provenance before blaming the download. An npm package with `bin\multiagentor-cli.js` must be reached through its npm shim/npx/portable wrapper; a full bundle must be reached through its root `.cmd`. If a raw EXE was used, preserve the existing task ID, correct the launcher, and do not create a replacement task.
6. Do not claim that a full bundle will download a browser on the next launch, and do not claim that an npm `.tgz` already contains a browser. State which artifact type was actually verified.
7. Redact tokens, cookies, authorization headers, passwords, and sensitive script input in any explanation.
8. Do not rerun automatically if the run could repeat external side effects. Offer a corrected rerun choice first.

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

1. One sentence stating the current workflow stage and what was discovered.
2. A 2-3 option choice set with the recommendation first and the effect of each option.
3. Exact names/IDs or parameter values needed to make the decision concrete.
4. One concise question, then pause for the answer before performing the selected mutation.

When ready to act or hand off, provide:

- The chosen values and defaults.
- The exact PowerShell command or the result of executing it.
- The created task/run ID when present.
- One next command for status or logs.

Avoid dumping the full command catalog unless the user asks for reference documentation.
