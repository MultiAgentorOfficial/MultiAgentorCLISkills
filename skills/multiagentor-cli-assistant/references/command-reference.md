# MultiAgentor CLI command reference

This reference reflects `multiagentor-cli.exe` version 0.3.1 help in the bundled project. Run the relevant `--help` command and prefer live output if versions differ.

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

## Scripts

```powershell
multiagentor-cli --json script categories
multiagentor-cli --json script my [--name <text>] [--description <text>] [--category <text>] [--page 1] [--size 10]
multiagentor-cli script execute-detail --id <scriptId>
```

`execute-detail` returns metadata, README, and `scriptContext` defaults. Use it before constructing overrides.

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
