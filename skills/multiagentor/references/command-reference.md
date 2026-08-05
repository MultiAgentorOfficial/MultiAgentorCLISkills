# MultiAgentor CLI command reference

This reference describes the currently supported command shape. Always run the relevant installed `multiagentor-cli --help` command first and treat live output as authoritative when capabilities differ.

## Version checks and updates

The skill version is stored in `VERSION` and is independent of the npm CLI version. Run exactly one skill update check at the beginning of a new MultiAgentor workflow:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <installed-skill>\scripts\update-skill.ps1
```

```bash
sh <installed-skill>/scripts/update-skill.sh
```

The updater compares strict SemVer with the official GitHub `main` branch. A clean Git checkout receives `git pull --ff-only`; a standalone installation receives a validated archive replacement with a timestamped backup. It refuses to overwrite a dirty Git worktree. When JSON reports `restart_required: true`, stop and start a new agent task before using the updated skill.

For a global npm-managed CLI, compare and update through the packaged helper:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <installed-skill>\scripts\update-cli.ps1
```

```bash
sh <installed-skill>/scripts/update-cli.sh
```

These helpers resolve `npm view multiagentor-cli@latest version`, install that exact version when it differs from the global package, verify `npm list --global`, and run `--help`. Rerunning a portable bootstrap applies the same check to its isolated CLI. Do not silently convert offline bundles, local tarballs, pinned packages, or custom executors to the npm latest channel.

## Install from npm

Node.js 18 or newer is required. Detect the platform first. The current package metadata is authoritative; the package inspected while updating this reference exposes `win32-x64` and Apple Silicon `darwin-arm64`, not Intel macOS. For a reusable command:

```powershell
npm.cmd install --global multiagentor-cli@latest
multiagentor-cli --help
```

```bash
npm install --global multiagentor-cli@latest
multiagentor-cli --help
```

When global installation is unavailable, use npx without an interactive install prompt:

```powershell
npx.cmd --yes multiagentor-cli@latest --help
npx.cmd --yes multiagentor-cli@latest auth oauth
```

```bash
npx --yes multiagentor-cli@latest --help
npx --yes multiagentor-cli@latest auth oauth
```

If Node.js/npm is missing or Node.js is older than 18, run the skill's portable bootstrap for the host platform.

Windows x64:

```powershell
$runtime = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File <installed-skill>\scripts\bootstrap-portable-cli.ps1 |
    Select-Object -Last 1 |
    ConvertFrom-Json
& $runtime.invocation --help
```

Apple Silicon macOS:

```bash
runtime_json=$(sh <installed-skill>/scripts/bootstrap-portable-cli.sh | tail -n 1)
invocation=$(printf '%s' "$runtime_json" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>process.stdout.write(JSON.parse(s).invocation))')
"$invocation" --help
```

The Windows script verifies the official Node.js ZIP and installs under `%APPDATA%\multiagentor\portable-runtime`. The macOS script requires `Darwin arm64`, verifies the official Node.js `darwin-arm64` tarball, and installs under `${MULTIAGENTOR_HOME:-$HOME/Library/Application Support/multiagentor}/portable-runtime`. Both install the current CLI into an isolated cache, create a reusable native launcher, avoid machine-wide PATH changes, and return JSON containing `invocation`. Stop clearly on unsupported architectures rather than attempting emulation.

The published npm tarball contains `bin/multiagentor-cli.js`, `bin/runtime-manager.js`, platform-native CLI binaries, and matching packaged `multi-agentor-script-core` binaries, but not the browser. npm-generated commands route through `bin/multiagentor-cli.js`. The first npm-launched `run start` or `run execute` installs/verifies script core, downloads and verifies the configured platform browser, sets `MULTIAGENTOR_SCRIPT_CORE_COMMAND` and `MULTIAGENTOR_BROWSER_EXECUTABLE`, and then starts the native CLI. Data is cached under `%APPDATA%\multiagentor` on Windows or `~/Library/Application Support/multiagentor` on macOS unless `MULTIAGENTOR_HOME` overrides it. Help, authentication, configuration, and remote CRUD do not trigger the browser download.

Never execute a native binary under `node_modules/multiagentor-cli/dist/<platform>/` directly for a local run. It bypasses the JavaScript runtime manager and can fail on a clean machine before script core/browser preparation. Keep one of these launch paths intact:

```text
Windows npm shim: multiagentor-cli.cmd -> bin/multiagentor-cli.js -> dist/win32-x64/multiagentor-cli.exe
macOS npm shim:   multiagentor-cli -> bin/multiagentor-cli.js -> dist/darwin-arm64/multiagentor-cli
npx:              npx multiagentor-cli -> bin/multiagentor-cli.js -> platform native CLI
portable:         OS launcher -> npm shim -> bin/multiagentor-cli.js -> platform native CLI
```

An extracted full offline bundle is a different artifact: verify its root launcher and matching platform script-core/browser paths. Do not apply npm download expectations to a full bundle, assume a Windows `.cmd` exists on macOS, or treat an extracted npm `.tgz` as a full bundle.

### Runtime-readiness sequence

`npm install` installs the command but does not necessarily download the browser. For local execution, the installed npm launcher must block task startup in this order when its package/runtime metadata requires these components:

1. Check the npm package's native CLI, `multi-agentor-script-core`, and `script-core-manifest.json` for the detected platform key.
2. Install/reuse script core under `<multiagentor-data>/runtime/<platform>/versions/<hash>/` and apply executable mode on macOS.
3. Use an existing `MULTIAGENTOR_BROWSER_EXECUTABLE` only when that file exists; otherwise fetch and validate the HTTPS browser manifest.
4. Reuse a valid cache or download the platform browser ZIP, check declared size and SHA-256, extract atomically, confirm the declared executable, apply mode `0755` on macOS, and update `browsers/current.json`.
5. Set `MULTIAGENTOR_SCRIPT_CORE_COMMAND` and `MULTIAGENTOR_BROWSER_EXECUTABLE`, then spawn the platform-native CLI with the original arguments.

If steps 1-4 fail, the launcher must exit nonzero before spawning the Go CLI. Treat this as runtime preparation failure: repair or retry the same task through the same launcher, never bypass the gate. Check live help for a public preparation command; when none exists, do not invent a dummy run or call internal JavaScript APIs directly merely to warm the cache.

## Global flags

```text
--base-url <url>   Temporary API base URL override
--token <token>    Bearer token override; never expose it in conversation
--config <path>    Config file override
--db <path>        SQLite database override
--json             JSON output for list commands; place before the command
--debug            Request method and URL on stderr
```

## Authentication and configuration

```powershell
multiagentor-cli auth oauth [--device-name <name>] [--client-id <id>]
multiagentor-cli auth logout
multiagentor-cli config show
multiagentor-cli config set base-url <url>
multiagentor-cli config set db-path <path>
multiagentor-cli config set executor-command <command...>
```

Normal installed builds already contain defaults. OAuth opens the default browser, polls for approval, and saves the token.

## Guided new-task sequence

Use this order for a new automation:

1. Authenticate with `auth oauth` and wait for success.
2. List existing browser environments with `--json browser list`.
3. Ask whether to use an existing environment or create one. If the list is empty or creation is chosen, inspect `--json browser systems`, then use `browser quick-create` and capture its browser ID.
4. Discover and choose a script, then call `script execute-detail` and resolve execution parameters.
5. Show the resolved browser, script, parameters, and task name; ask whether to create-and-run, create-only, or return to modify.
6. Create the remote task with the chosen browser ID and script ID only after that choice.
7. Parse the returned task ID and execute it with `run start` only when immediate execution was selected.

Do not reorder browser and script selection for a new task. Existing-task runs may go directly to `run start` because the cached task payload already contains both bindings.

## Scripts

```powershell
multiagentor-cli --json script list [--name <text>] [--description <text>] [--category <text>] [--page 1] [--size 10]
multiagentor-cli --json script categories
multiagentor-cli --json script my [--name <text>] [--description <text>] [--category <text>] [--page 1] [--size 10]
multiagentor-cli script execute-detail --id <scriptId>
```

`script list` calls `/v1/script-market` and searches the full market. `script my` calls `/v1/script-market/my` and lists scripts available to the current user. Both list commands support fuzzy name, description, and category filters; place global `--json` before `script` to receive the original JSON page response.

For task creation, search `script my` first and fall back to `script list` when there is no suitable personal result. A selected market script may proceed directly to `execute-detail` and task creation; do not require it to also appear in `script my`. If the server later rejects access, treat that response as authoritative and offer another personal or market candidate. `execute-detail` returns metadata, README, and `scriptContext` defaults; call it for the selected script before constructing overrides.

## Browser environments

```powershell
multiagentor-cli --json browser systems
multiagentor-cli --json browser list [--search <text>] [--page 1] [--size 10]
multiagentor-cli browser quick-create --name <name> --system-os <os> --system-version <version[,version...]>
```

Quick create requires a non-empty name up to 100 characters, a system OS returned by `browser systems`, and 1-20 comma-separated versions. The server fixes the browser kernel to Chrome 148.

## Remote tasks and cached runnable payloads

```powershell
multiagentor-cli task create --name <name> --browser-id <browserId> --script-id <scriptId> [--type local] [--script-context <json> | --script-context-file <path>]
multiagentor-cli task create --file <json> [--script-context <json> | --script-context-file <path>]
multiagentor-cli task update --id <taskId> --name <name> --browser-id <browserId> --script-id <scriptId> [--type local] [--script-context <json> | --script-context-file <path>]
multiagentor-cli task update --id <taskId> --file <json> [--script-context <json> | --script-context-file <path>]
multiagentor-cli --json task list [--page 1] [--size 20]
multiagentor-cli task get --id <taskId> [--full]
multiagentor-cli task refresh --id <taskId> [--script-context <json> | --script-context-file <path>]
multiagentor-cli task delete --id <taskId>
```

Create/update call the remote task API, fetch `/cli`, and cache the runnable payload in SQLite. List only syncs summaries. A context object is the direct optional `/cli` request body. Omit context flags to use script defaults; explicitly pass `{}` to clear defaults.

Create a UTF-8 context file and prefer `--script-context-file` for task creation and other context-bearing operations on both platforms. This avoids PowerShell 5.1 quote loss and zsh/bash quoting mistakes. Preserve the complete `options`/`vars` object from `execute-detail` when overriding one value.

## Local runs

```powershell
multiagentor-cli run start --task-id <taskId> [--script-context <json> | --script-context-file <path>] [--executor-command <command>]
multiagentor-cli run execute --task-file <path|-> [--executor-command <command>]
multiagentor-cli --json run list --task-id <taskId> [--page 1] [--size 20]
multiagentor-cli run get --run-id <runId> [--full]
multiagentor-cli run logs --run-id <runId>
multiagentor-cli run cancel --run-id <runId>
```

`run start` normally uses the cached payload. A supplied context is fetched for that run only. `run execute` validates and preserves one UTF-8 JSON object, writes it under `<multiagentor-data>/direct-runs/<runId>/`, and creates no remote task or SQLite task/run record. `<multiagentor-data>` is `%APPDATA%\multiagentor` on Windows and `~/Library/Application Support/multiagentor` on macOS unless overridden by `MULTIAGENTOR_HOME`.

Starting a run is not completing a run. Unless the user explicitly requests background/start-only behavior, keep the agent session active until `run get --full` or the foreground launcher reports a terminal state. If foreground waiting is unsuitable for the host:

1. Start the resolved launcher with the host's supported hidden background-process mechanism.
2. Capture stdout/stderr and retain the process handle when available.
3. For `run start`, resolve the run ID from output or the newest matching entry from `--json run list --task-id <taskId>`, then poll `run get --run-id <runId> --full`.
4. For `run execute`, supervise the process handle, captured output, and `<multiagentor-data>/direct-runs/<runId>/` logs because it creates no SQLite run record.
5. Continue until the current CLI/process reports success, failure, cancellation, or another documented terminal state.
6. Recover from tool timeout/disconnection by querying the run or process/log state again; do not interpret tool timeout as task completion or failure.
7. At terminal state, collect the task result before returning:
   - For `run start`, call `run get --run-id <runId> --full`, then inspect its result/output fields and any artifact paths it returns.
   - For `run execute`, parse the final JSON summary and inspect the named artifacts in `<multiagentor-data>/direct-runs/<runId>/`; it has no `run get` record.
   - Prefer structured JSON/output artifacts. Fall back to `stdout.log` or `script-core.log` when necessary, and inspect lifecycle plus `stderr.log` for failures.
   - Read and summarize the result content for the agent. Do not stop after reporting a file path. For large outputs, report schema, counts, key findings, and representative records while linking or naming the full artifact.
   - If the process reports success but no usable result can be found, state that explicitly and inspect logs instead of inventing output.
8. Return the final status, progress, collected result summary, and artifact paths. A waited run is not complete from the agent's perspective until result collection finishes.

Only an explicit user instruction such as “启动后不用等待” permits returning while the run remains active. In that mode, return the task/run IDs, last state, and commands for `run get` and `run logs`.

Task-run files are normally under `<multiagentor-data>/tasks/<taskId>/runs/<runId>/`:

```text
task.json
lifecycle.jsonl
stdout.log
stderr.log
script-core.log
```

Exit code 0 means success; a non-zero executor exit means failure.
