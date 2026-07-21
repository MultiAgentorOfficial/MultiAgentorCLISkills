# MultiAgentor CLI command reference

This reference reflects the published `multiagentor-cli` version 0.3.2 live help. Run the relevant `--help` command and prefer live output if versions differ.

## Install from npm

Node.js 18 or newer is required. For a reusable command:

```powershell
npm.cmd install --global multiagentor-cli@latest
multiagentor-cli --help
```

When global installation is unavailable, use npx without an interactive install prompt:

```powershell
npx.cmd --yes multiagentor-cli@latest --help
npx.cmd --yes multiagentor-cli@latest auth oauth
```

If Node.js/npm is missing or Node.js is older than 18, run the skill's portable bootstrap script with Windows PowerShell:

```powershell
$runtime = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File <installed-skill>\scripts\bootstrap-portable-cli.ps1 |
    Select-Object -Last 1 |
    ConvertFrom-Json
& $runtime.invocation --help
```

The script downloads the newest compatible Node.js LTS ZIP for Windows x64 or ARM64 from `nodejs.org`, checks it against the release's official `SHASUMS256.txt`, extracts it under `%APPDATA%\multiagentor-cli\portable-runtime`, installs the CLI in that isolated cache, and creates `multiagentor-cli-portable.cmd`. It does not modify the system PATH or install Node.js machine-wide. Reuse `$runtime.invocation` for all later commands in the workflow.

The npm package includes the Windows x64 Go CLI and RPA Agent, but not the browser. The first npm-launched `run start` or `run execute` downloads and verifies the configured browser runtime, then caches the Agent and browser under `%APPDATA%\multiagentor-cli\`. Help, authentication, configuration, and remote CRUD do not trigger the browser download.

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

In Windows PowerShell, create a UTF-8 context file and prefer `--script-context-file` for task creation and other context-bearing operations. PowerShell 5.1 may remove embedded JSON quotes when passing an inline string to a native EXE, causing local JSON parsing to fail before the API call. Preserve the complete `options`/`vars` object from `execute-detail` when overriding one value.

## Local runs

```powershell
multiagentor-cli run start --task-id <taskId> [--script-context <json> | --script-context-file <path>] [--executor-command <command>]
multiagentor-cli run execute --task-file <path|-> [--executor-command <command>]
multiagentor-cli --json run list --task-id <taskId> [--page 1] [--size 20]
multiagentor-cli run get --run-id <runId> [--full]
multiagentor-cli run logs --run-id <runId>
multiagentor-cli run cancel --run-id <runId>
```

`run start` normally uses the cached payload. A supplied context is fetched for that run only. `run execute` validates and preserves one UTF-8 JSON object, writes it under `%APPDATA%\multiagentor-cli\direct-runs\<runId>\`, and creates no remote task or SQLite task/run record.

Task-run files are normally under `%APPDATA%\multiagentor-cli\tasks\<taskId>\runs\<runId>\`:

```text
task.json
lifecycle.jsonl
stdout.log
stderr.log
agent.log
```

Exit code 0 means success; a non-zero executor exit means failure.
