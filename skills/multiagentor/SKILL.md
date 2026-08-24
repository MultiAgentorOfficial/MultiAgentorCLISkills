---
name: multiagentor
description: "Self-check, repair, update, install, guide, and operate MultiAgentor skill and CLI on Windows and Apple Silicon macOS for login, browser/Cookie/proxy choices, script discovery, local task CRUD and batch import, supervised execution, result collection, repeat-run prompts, logs, cancellation, and configuration. Use when a user asks to install, update, or use multiagentor-cli; run RPA even when the CLI is absent; choose or prepare a browser profile; import extension-exported Cookies; create or run local tasks; repeat a completed task; or diagnose a failure."
---

# MultiAgentor

Turn the user's goal into a valid MultiAgentor CLI workflow. Reduce cognitive load: discover what can be discovered, recommend a choice with a reason, and only ask about information that cannot be inferred safely.

## Start here

1. Restate the intended outcome in one short sentence.
2. Run the **version-update gate** once before CLI/API discovery. If the skill updates, stop and ask the user to start a new agent task so the new instructions load.
3. Bootstrap or update the CLI before API discovery. Prefer the published npm package when no trusted project bundle is already in scope; follow **Install or select the CLI** below.
4. Run the selected invocation with `--help` and treat live help as authoritative.
5. Authenticate before protected discovery. Run `auth oauth` when login is requested, no usable token exists, or a discovery command reports an authentication failure; wait for successful authorization before continuing.
6. For a new automation, preserve this order: **login → choose/create and prepare browser environment → choose script and execution parameters → assemble and create the local task → run task**. Do not select the script before resolving the browser environment.
7. Use read-only discovery commands before asking the user for IDs or supported values.
8. Build a parameter state table internally: known, discovered, safely defaulted, missing, ambiguous, or consequential.
9. Ask only about missing, ambiguous, or consequential values, except that browser mode selection and task execution parameters are explicit user choices for every new task. Continue automatically after the answer when the requested action authorizes it.

Read [references/command-reference.md](references/command-reference.md) when assembling a command or diagnosing behavior.

## Enforce the version-update gate

Treat skill version and CLI version as independent.

1. Run the OS updater once at the start of each new MultiAgentor workflow. It self-checks `VERSION`, skill identity, command reference, UI metadata, and updater files before checking GitHub:
   - Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File <skill>/scripts/update-skill.ps1`
   - macOS: `sh <skill>/scripts/update-skill.sh`
2. The updater checks the official `MultiAgentorOfficial/MultiAgentorCLISkills` repository. When a newer strict SemVer exists—or a standalone installation fails integrity checks—update or repair immediately as the user requested:
   - In a clean Git worktree, use `git pull --ff-only origin main`.
   - In a standalone installed skill, download the official GitHub archive, validate `VERSION` and `name: multiagentor`, stage beside the installation, retain a timestamped backup, and atomically replace the directory with rollback on failure.
3. Never discard local modifications or force/reset a Git worktree. If it is dirty, report the newer version and stop for user direction.
4. Inspect the updater JSON. Require `integrity_ok: true`. If `updated` and `restart_required` are true, report old/new versions and backup path, then end the current workflow. Ask the user to start a new Codex/WorkBuddy task; the currently loaded skill text remains in agent context and must not be treated as refreshed.
5. If the check cannot reach GitHub, report that freshness is unverified. Do not claim the skill is current. Continue with the installed skill only when the user allows offline continuation or the active request already explicitly permits it.
6. Do not run the updater repeatedly within one workflow and never update while a local RPA run is active.

After the skill gate passes, check CLI freshness before authentication or task work:

- Global npm installation: run the OS-specific `scripts/update-cli.ps1` or `scripts/update-cli.sh`. Compare the installed package with `npm view multiagentor-cli@latest version`; install the exact resolved latest version when different, then verify npm's installed version and `--help`.
- Portable installation: rerun the OS portable bootstrap. It performs the same npm latest comparison and updates its isolated package when needed.
- `npx --yes multiagentor-cli@latest`: retain the full prefix; npm resolves the current dist-tag for that invocation.
- Full offline bundle, local `.tgz`, explicitly pinned package, or custom executor: do not silently replace its provenance with npm. Report the detected version/source and offer migration to the npm latest channel when appropriate.

Complete all version updates before resolving and reusing one CLI invocation. Never update the CLI midway through a run.

## Install or select the CLI

Resolve one stable invocation and reuse it for the entire workflow.

1. Detect OS and CPU architecture before installation (`$PSVersionTable.Platform`/environment plus architecture on Windows; `uname -s` and `uname -m` on macOS). Inspect the installed/latest npm package metadata when support may have changed. At the time represented by this skill, the published package supports `win32-x64` and `darwin-arm64`; do not attempt local execution on Intel macOS, Windows ARM64, Linux, or a platform key absent from the package. Remote-only commands may still work only if a compatible CLI executable is actually supplied.
2. Classify a user-supplied artifact before choosing an entry point:
   - An npm installation or extracted npm `.tgz` contains `bin/multiagentor-cli.js` plus platform directories such as `dist/win32-x64/` and `dist/darwin-arm64/`. Invoke only the npm-generated `multiagentor-cli` shim, `npx`, or a skill-generated portable launcher. Never invoke the package-internal native executable directly: doing so bypasses script-core/browser preparation. If only a `.tgz` was supplied, install it with npm.
   - A full offline bundle must contain its root launcher plus matching platform script-core and browser artifacts. Verify its own instructions and paths; do not infer Windows bundle names on macOS or treat an npm tarball as a full bundle.
   Do not download a duplicate CLI merely because a valid launcher is not global.
3. Otherwise locate `multiagentor-cli` using the host shell (`Get-Command` on Windows, `command -v` on macOS).
4. If the command is absent, check `node --version` and `npm --version`; require Node.js 18 or newer.
5. If Node.js/npm is missing, outdated, or unusable, choose the bundled portable bootstrap for the detected OS:
   - Windows x64: [scripts/bootstrap-portable-cli.ps1](scripts/bootstrap-portable-cli.ps1), which verifies the official Node.js ZIP and installs under `%APPDATA%\multiagentor\portable-runtime`.
   - Apple Silicon macOS: [scripts/bootstrap-portable-cli.sh](scripts/bootstrap-portable-cli.sh), which verifies the official `darwin-arm64` Node.js tarball and installs under `${MULTIAGENTOR_HOME:-$HOME/Library/Application Support/multiagentor}/portable-runtime`.

   Windows invocation:

   ```powershell
   $runtime = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bootstrap-portable-cli.ps1 |
       Select-Object -Last 1 |
       ConvertFrom-Json
   & $runtime.invocation --help
   ```

   macOS invocation:

   ```bash
   runtime_json=$(sh /path/to/installed-skill/scripts/bootstrap-portable-cli.sh | tail -n 1)
   invocation=$(printf '%s' "$runtime_json" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>process.stdout.write(JSON.parse(s).invocation))')
   "$invocation" --help
   ```

   Resolve the script path relative to this installed skill, not the user's current directory. Reuse the returned `invocation` for the entire workflow. Do not modify the machine-wide PATH or install system-wide Node.js. Network/sandbox approval may still be required by the active environment; request it when the tool reports that requirement. Report the official download source, selected version/platform, cache path, and checksum result without dumping npm logs.
6. If compatible Node.js/npm is already available, prefer the current npm release for a reusable workflow. For an existing global npm installation, run `update-cli.ps1`/`update-cli.sh`; otherwise install the current release. Use `npm.cmd` on Windows PowerShell and `npm` on macOS:

   ```powershell
   npm.cmd install --global multiagentor-cli@latest
   multiagentor-cli --help
   ```

7. If global installation is unavailable because of permissions or PATH, fall back to the non-interactive npm launcher and use the full OS-appropriate prefix for every later command:

   ```powershell
   npx.cmd --yes multiagentor-cli@latest --help
   ```

   Invocation prefix: `npx.cmd --yes multiagentor-cli@latest`

   macOS prefix: `npx --yes multiagentor-cli@latest`

8. Do not mix a full-bundle launcher, portable launcher, global npm shim, npx, or a package-internal executable within one workflow unless diagnosing an installation problem. Never shorten a resolved npm/portable invocation to the native Go executable path.
9. `--help`, auth, config, and remote CRUD do not download the browser. On the first npm-launched `run start` or `run execute`, allow the JavaScript launcher to install the packaged `multi-agentor-script-core`, download the platform browser ZIP, verify size and SHA-256, extract atomically, set executable permissions on macOS, set `MULTIAGENTOR_SCRIPT_CORE_COMMAND` and `MULTIAGENTOR_BROWSER_EXECUTABLE`, and only then start the native CLI. Do not interrupt this preparation.
10. Reuse the cached verified browser on later runs. Accept a user-supplied `MULTIAGENTOR_BROWSER_EXECUTABLE` only when it is an absolute, existing compatible executable. Do not substitute ordinary Chrome or guess a platform-specific executable name.

Installation is an expected prerequisite when the user asks to run an RPA task and no CLI is available. Report the chosen installation method and verified invocation without dumping npm logs.

### Enforce the runtime-readiness gate

Treat npm installation and local runtime readiness as separate states. `npm install` alone is not proof that a task can run. For every npm/portable `run start` or `run execute`, preserve the installed package's JavaScript launcher as a blocking readiness gate before the Go CLI:

1. Confirm Node.js 18+, the selected npm/portable launcher, `bin/multiagentor-cli.js`, the current platform's native CLI, packaged `multi-agentor-script-core`, and `script-core-manifest.json` exist. If the installed npm package lacks the detected platform key, stop as unsupported; otherwise repair/reinstall incomplete files before attempting the task.
2. Let the launcher install/reuse the verified script core under the platform data root: `%APPDATA%\multiagentor\runtime\win32-x64\` on Windows or `~/Library/Application Support/multiagentor/runtime/darwin-arm64/` on macOS (unless `MULTIAGENTOR_HOME` overrides the root).
3. Let it resolve `MULTIAGENTOR_BROWSER_EXECUTABLE`: honor a supplied executable only if its absolute path exists; otherwise use the browser artifact declared for the current platform, download its ZIP when no valid cache exists, verify declared size and SHA-256, extract atomically, confirm the declared native executable, set mode `0755` on macOS, and update `browsers/current.json`.
4. Require both resolved script-core and browser paths. The launcher must set `MULTIAGENTOR_SCRIPT_CORE_COMMAND` and `MULTIAGENTOR_BROWSER_EXECUTABLE` before it spawns the native CLI. Do not manually start the native executable while preparation is pending.
5. If any readiness step fails, stop before task execution, report the platform and failed preparation stage, and offer retry/repair. Do not describe the task as running, create a replacement task, bypass the launcher, or advise disabling macOS security controls globally.

Check live help before assuming a separate runtime-preparation command exists. When none is exposed, treat the readiness gate as the blocking prefix of the first correctly launched `run start` or `run execute`; wait through it and distinguish its preparation messages from task progress. Later runs may reuse a valid cached browser according to the installed launcher's documented cache/fallback behavior.

### Supervise every started run

Default to **start and wait**. A successful process launch, created task ID, created run ID, readiness completion, or first progress update is not task completion and does not authorize ending the agent session.

1. Before starting, resolve the user's wait preference:
   - If the user explicitly says “启动后不用等待”, “后台运行”, “只启动”, “不用等结果”, or an equivalent instruction, use **start without waiting**.
   - Otherwise use **start and wait** automatically. Do not ask a redundant wait-choice question merely because the task may take a long time.
2. Prefer the resolved launcher in the foreground when the host can keep the command open. Treat its exit as meaningful only after confirming the corresponding run state.
3. If the host cannot safely hold one long-running tool call, use its supported background/monitor mechanism, keep GUI-less helper processes hidden on Windows, and capture stdout/stderr. For `run start`, resolve the new run ID from command output or `--json run list --task-id <taskId>`, then poll `run get --run-id <runId> --full`. For `run execute`, which has no SQLite task/run record, supervise the process handle plus its captured output and platform direct-run directory instead of calling `run get`. Keep the agent turn/session active while monitoring.
4. Continue supervision until the current CLI reports a terminal run state. Do not assume exact status names without inspecting live output; states equivalent to success, failure, or cancellation are terminal, while queued, preparing, starting, or running states are not.
5. If a tool call times out, disconnects, or returns before terminal state, immediately re-read a `run start` record with `run list`/`run get`, or re-check the `run execute` process and direct-run logs, then resume supervision. A tool timeout is not a run failure and not permission to end the session.
6. Provide concise progress updates during a long run without flooding the user. Include the run ID, current state/progress, and any material stage change.
7. At terminal state, perform **result collection** before ending the session:
   - For `run start`, call `run get --run-id <runId> --full` and inspect its complete output/result fields and every result artifact path it exposes.
   - For `run execute`, parse the command's final JSON summary, identify its direct-run directory, and inspect the result/output artifacts named there. Because it has no SQLite record, do not substitute `run get`.
   - Prefer structured result JSON or explicit output artifacts. Use `stdout.log` and `script-core.log` only when structured output is absent or incomplete; use lifecycle and `stderr.log` to explain failure.
   - Read the result contents, not merely their paths. For large artifacts, inspect enough of their schema, summary, counts, and representative records to accurately describe the outcome; offer the exact path for full data. Never dump secrets, cookies, tokens, or excessive raw records.
   - Return the collected result to the current agent context, summarize what the automation produced, and answer the user's original goal from that result. Treat “run succeeded but result was not read” as incomplete.
8. Report the final status, progress, collected result summary, and relevant artifact paths. If the run succeeded but no usable result exists, say so explicitly, inspect the logs for why, and do not invent a result.
9. After any waited run reaches terminal state and result collection finishes, produce one **copyable repeat-run prompt** for the user:
   - Write it as a natural-language request to `$multiagentor`, not merely a shell command.
   - Include the stable task ID and human-readable task name, the saved/default versus one-run context mode, safe effective parameters needed to reproduce the run, the instruction to wait for terminal state, and the instruction to read and summarize results.
   - Start with Skill/CLI self-check and upgrade. If the Skill updates, instruct the future agent to continue in a new task after reload.
   - Exclude the previous run ID, tokens, cookies, proxy credentials, passwords, temporary files, and transient log/result paths. Replace required secrets with “ask me securely before running”.
   - If repeating could submit, purchase, message, upload, mutate data, or cause another external side effect, require confirmation immediately before the repeated run.
   - For `run execute`, include a durable task-file path only when it is expected to remain available; otherwise instruct the agent to ask the user to provide the task JSON again.
10. Only in **start without waiting** mode may the session end while the run is active. Report the task ID, run ID when available, last observed state, and exact status/log commands so the user can return later. A repeat-run prompt is optional in this mode because effective results are not yet known.

Never convert start-and-wait into start-without-wait because of expected duration, host tool timeout, sparse output, or the fact that the RPA/browser process is visibly running.

## Intent routing

Map natural-language requests to these flows:

| User goal | Flow |
| --- | --- |
| First use, login, authorization | `auth oauth` |
| Create and run a new automation | login → browser choice → script choice → task creation → `run start` |
| Browse the full script market | `script list` |
| Choose a script for task execution | `script my`, then `script list` when no suitable personal result exists |
| Create or choose a browser environment | browser discovery / `quick-create` |
| Import browser-extension Cookies | `browser cookie-import` |
| Create a reusable automation task | task creation |
| Import several reusable tasks | `task create-batch` |
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
3. Proxy mode for every new browser environment: no proxy, inline environment proxy, or an applicable local default/environment-specific execution proxy.
4. Optional Cookie preparation when the user needs an existing login/session: skip, merge imported Cookies, or replace profile Cookies.
5. Script resolution: choose from at most three ranked real scripts.
6. Script parameters: use defaults, customize values, or view explanations.
7. Final task summary: create and run now, create without running, or return to modify the browser/script/parameters.

Put the recommended option first and explain its effect in one sentence. Preserve exact IDs but pair them with human-readable names. Do not ask for values that discovery can provide, repeat a decision the user already made explicitly, or add confirmation to read-only commands. Destructive actions still follow the stricter confirmation rules below.

### Choose a browser environment before scripts

For every new task, resolve the browser immediately after authentication and before script discovery:

1. Run `--json browser list` to discover existing environments.
2. If one or more environments exist, explicitly offer:
   1. 使用已有浏览器环境（推荐 when a suitable match exists）— show at most three ranked environments with exact IDs.
   2. 创建新的浏览器环境 — inspect `--json browser systems`, then offer valid OS/version choices.
3. If no environments exist, state that clearly and run `--json browser systems`. Do not ask the user to provide a browser ID that does not exist, and do not proceed to script selection until creation succeeds.
4. Before creating any new environment, always ask whether to use a proxy. Inspect live help, then present supported choices. When supported, `browser quick-create` defaults to `--proxy-mode no` and accepts an inline HTTP/SOCKS5 proxy with `--proxy-mode merge`; `browser proxy` can later update or remove that remote environment's proxy.
5. Never request proxy credentials until a supported secure configuration path is identified. Never print, log, persist in task context, or include proxy username/password/token in the repeat-run prompt. Show only a redacted endpoint or non-secret proxy label when confirmation is needed.
6. Derive a short browser name from the target/OS when naming is unimportant; ask only when the user wants a specific name. Environment creation changes remote state, so show the chosen name, OS, version, and proxy mode immediately before executing it unless the user's request already authorized those exact values.
7. Parse the selected or newly created browser ID and retain it for task creation. Never invent an ID.

If the user supplied a browser ID, confirm it appears in discovery results and treat the browser step as resolved. Running an existing task does not require this choice because its cached payload already identifies the browser and script.

### Prepare persistent browser state

Each browser environment ID maps to one fixed local UserData Profile. Later tasks using that ID reuse its Cookies and browser state; different data roots or login identities remain isolated.

- When the user supplies browser-extension Cookie JSON, inspect `browser cookie-import --help`, validate that the file exists and is a UTF-8 JSON array, then ask for `merge` or `replace` unless already specified. `merge` is the safe default and preserves unrelated Cookies; `replace` clears existing profile Cookies first and requires a clear consequence statement.
- Run `browser cookie-import --id <browserId> --file <cookies.json> [--mode merge|replace]` only through the resolved npm/portable launcher. Let it prepare the current script core and browser runtime. Cookie contents stay in the current machine's profile and are not uploaded or stored in the CLI database; never print or copy them into task JSON, logs, repeat prompts, or commits.
- Distinguish remote environment proxy commands (`browser quick-create` / `browser proxy`) from local execution proxy overrides (`config proxy`). A local environment-specific proxy overrides the local default; without either, preserve the task payload's own proxy. Before setting or clearing a working local proxy, show the scope and consequence and ask for confirmation. Never expose stored credentials; `config proxy show` masks passwords.
- The local proxy affects browser traffic only, not OAuth, API, npm, or runtime downloads.

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
3. 保存自定义参数到任务 — replace `payload.context` in a complete local task JSON and use `task create`, `task update`, or `task refresh` with `--file`.

For task create/update/refresh, write the complete runnable task object as UTF-8 JSON and pass `--file`; do not pass obsolete task-construction or context flags. For a one-run context override, prefer `run start --script-context-file`, validate a top-level object, and preserve the full `options`/`vars` structure.

## Workflow recipes

### Create and optionally run a task

1. Verify the CLI invocation, then authenticate with `auth oauth` when needed. Do not continue protected discovery until login succeeds.
2. Run `--json browser list` and explicitly ask whether to use an existing environment or create a new one when existing environments are available.
3. If the user chooses creation or the list is empty, run `--json browser systems`, resolve a valid name/OS/version choice, and explicitly ask for proxy mode. Use live-help-supported `browser quick-create` inline proxy flags when selected; otherwise create without proxy or guide a supported alternative, then rediscover and parse the browser ID.
4. Discover scripts only after the browser ID is resolved. Search `--json script my` first with the user's business terms as `--name`, `--description`, or `--category` filters; when it has no suitable result, search `--json script list` with the same filters and present market candidates. Do not require a selected market script to appear in both results.
5. Immediately run `script execute-detail --id <scriptId>` after the script ID is chosen.
6. Present the script's configurable execution parameters and explicitly ask whether the user wants defaults, custom values, or more explanation. Resolve a complete execution payload from live output, preserve all required envelope fields, merge custom values into `payload.context`, and validate the resulting complete UTF-8 task JSON.
7. Derive a short task name from the chosen script and target; ask only if naming matters to the user.
8. Show a compact summary: browser, script, task name, chosen execution parameters/context mode, and proposed execution behavior.
9. Offer a final choice: 创建并立即运行（recommended when the user asked to run）、仅创建任务、返回修改选择. This is the correction checkpoint before task creation; do not create until it is resolved.
10. Create the task with `task create --file <task.json>` and parse the generated local task ID rather than asking the user to copy it manually. This makes no network request.
11. Run the new task with `run start --task-id <taskId>` only when the user chose immediate execution. Apply **Supervise every started run**: remain in the session until terminal state unless the user explicitly selected start without waiting. If the user chose create-only, report the task ID and the exact later run command.

For a version 1 batch document containing a non-empty `tasks` array of complete runnable task objects, validate every item and use `task create-batch --file <tasks.json>`. Creation is atomic: any validation failure leaves the local database unchanged.

### Run an existing task

1. If no task ID is given, list tasks and offer up to three matches.
2. Read `task get --id <id> --full`. Default to its cached complete payload when the user did not request a parameter override. Historical tasks with a complete cached payload retain their IDs; if payload is missing, require a complete local task JSON and repair it with `task refresh --id <id> --file <task.json>` before running.
3. If override intent is present, inspect the task/script and resolve only changed context fields.
4. Use the exact resolved full-bundle, portable, npm-shim, or npx invocation. Before a local run on a clean machine, confirm it does not target a package-internal native executable under `dist/<platform>/`. Apply the **runtime-readiness gate**; the npm/portable JavaScript launcher must remain in the call chain and must finish preparing script core/browser and injecting both paths before the native CLI may execute the task.
5. Treat runtime preparation output as the blocking prefix of the same first run. If it fails, stop and report a preparation failure rather than a task/script failure; if it succeeds, apply **Supervise every started run** and continue until terminal state unless the user explicitly requested start without waiting.
6. After terminal state, collect and read the result as required by **Supervise every started run**. Report the run ID, final status, progress, result summary, relevant result/log paths, and the copyable repeat-run prompt. In explicit start-without-wait mode, report the last observed state and the next inspection commands instead.

### Diagnose a failed run

1. Resolve the run ID from the user's input or `run list`.
2. Read `run get --full` and lifecycle logs.
3. Use the returned `output.log_files` paths to inspect `stderr.log` and `script-core.log` when needed.
4. Classify the failure before recommending a fix:
   - CLI/auth/API/configuration
   - browser runtime download or executable
   - invalid task envelope/context
   - multi-agentor-script-core process failure
   - macOS signature, notarization, quarantine, or execution permission
   - target website/script behavior
5. For a browser-executable failure at 0% on a clean machine, inspect OS/architecture and launcher provenance before blaming the download. An npm package with `bin/multiagentor-cli.js` must be reached through its npm shim/npx/portable wrapper on both Windows and macOS. If a package-internal native binary was used, preserve the existing task ID, correct the launcher, and do not create a replacement task.
6. Do not claim that a full bundle will download a browser on the next launch or that an npm `.tgz` contains the browser. State the verified artifact type, platform key, data root, script-core path, and browser path without exposing sensitive configuration.
7. On macOS, inspect executable mode and use read-only `codesign --verify --deep --strict <path>` and `spctl --assess --type execute <path>` when the OS blocks launch. Report the exact failing component. Do not globally disable Gatekeeper or remove quarantine recursively; ask before any targeted security-metadata change.
8. Redact tokens, cookies, authorization headers, passwords, and sensitive script input in any explanation.
9. Do not rerun automatically if the run could repeat external side effects. Offer a corrected rerun choice first.

## Confirmation and safety

Read-only discovery does not need confirmation. Respect the user's explicit request as authorization for ordinary in-scope create/run/update actions.

Ask for explicit confirmation immediately before:

- `task delete`, because it deletes the local task, its runs, and logs after checking for active runs.
- `auth logout`, because it clears the local token.
- `run cancel`, unless the user explicitly asked to stop that run.
- `config set`, when it replaces a working endpoint, database, or executor.
- A rerun that may duplicate submissions, purchases, messages, uploads, or other external effects.

Show the exact target ID/value and consequence in the confirmation. Never print a bearer token or the token fields returned by `config show`.

## Command construction rules

- Put global `--json` before the command: `multiagentor-cli --json task list`.
- Quote values containing spaces or shell metacharacters using the active shell's native quoting; never paste PowerShell syntax into zsh/bash or vice versa.
- For `task create`, `task update`, and `task refresh`, require `--file` containing a complete runnable UTF-8 task JSON. Use `task create-batch --file` only for a version 1 object with a non-empty `tasks` array.
- Preserve the full `options` and `vars` structure returned by `execute-detail` when changing one field, unless the script documentation explicitly supports a partial context.
- In Windows PowerShell 5.1, prefer `--task-file <path>` over stdin for non-ASCII JSON. If stdin is required, set `$OutputEncoding = [System.Text.UTF8Encoding]::new($false)` first.
- Parse returned JSON with `ConvertFrom-Json` on PowerShell or a real JSON parser on macOS; do not scrape IDs from formatted tables.
- Do not use `run execute` when the user expects a reusable local task or SQLite run record; it creates neither.
- When live help describes local-only task storage, treat tasks, task state, and run records as local-only. Do not claim task CRUD calls a remote task API.
- Do not start concurrent runs for the same browser environment ID. Different environment IDs may run concurrently. `run execute` should use `--environment-id` when persistent profile reuse and locking are required.

## Response shape

When waiting for a user choice, keep the response short:

1. One sentence stating the current workflow stage and what was discovered.
2. A 2-3 option choice set with the recommendation first and the effect of each option.
3. Exact names/IDs or parameter values needed to make the decision concrete.
4. One concise question, then pause for the answer before performing the selected mutation.

When ready to act or hand off, provide:

- The chosen values and defaults.
- The exact host-shell command or the result of executing it.
- The created task/run ID when present.
- After a waited run reaches terminal state, the actual collected result summary and its artifact path, not only the status.
- After a waited run, one fenced, copyable repeat-run prompt that follows the redaction and side-effect rules above.
- One next command for status or logs.

Avoid dumping the full command catalog unless the user asks for reference documentation.
