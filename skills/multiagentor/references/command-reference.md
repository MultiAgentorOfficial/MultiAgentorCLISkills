# MultiAgentor CLI command reference

Read this only when assembling an exact command. Run the relevant installed `--help` first; live output overrides this reference. Read the routed workflow reference for decision rules and safety.

## Version and installation

```powershell
multiagentor-cli version
multiagentor-cli --help
npm.cmd install --global multiagentor-cli@latest
npx.cmd --yes multiagentor-cli@latest --help
```

Use `npm` / `npx` on macOS. For Skill and portable update commands, read [installation-and-updates.md](installation-and-updates.md).

## Global flags

```text
--base-url <url>   API base URL override
--token <token>    Bearer token override; never expose it
--config <path>    Config file override
--db <path>        SQLite database override
--json             JSON output for supported list commands; place before command
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
multiagentor-cli config proxy set [--environment-id <id>] --protocol <http|https|socks5> --host <host> --port <1-65535> [credentials]
multiagentor-cli config proxy show [--environment-id <id>]
multiagentor-cli config proxy clear [--environment-id <id>]
```

## Scripts

```powershell
multiagentor-cli --json script categories
multiagentor-cli --json script my [--name <text>] [--description <text>] [--category <text>] [--page 1] [--size 10]
multiagentor-cli --json script list [--name <text>] [--description <text>] [--category <text>] [--page 1] [--size 10]
multiagentor-cli script execute-detail --id <scriptId>
```

`script my` searches authenticated scripts; `script list` searches the full market. Read [task-workflows.md](task-workflows.md) for fallback and parameter rules.

## Browser environments

```powershell
multiagentor-cli --json browser systems
multiagentor-cli --json browser list [--search <text>] [--page 1] [--size 10]
multiagentor-cli browser quick-create --name <name> --system-os <os> --system-version <version[,version...]> [--proxy-mode no|merge] [proxy flags]
multiagentor-cli browser proxy --id <browserId> --proxy-mode <no|merge> [proxy flags]
multiagentor-cli browser cookie-import --id <browserId> --file <cookies.json> [--mode merge|replace]
multiagentor-cli browser export --id <browserId> --file <bundle.json> [--force]
multiagentor-cli browser import --file <bundle.json>
multiagentor-cli browser launch --id <browserId>
```

Read [browser-workflows.md](browser-workflows.md) for proxy scopes, Cookie safety, migration-bundle handling, persistent Profile locking, manual-launch waiting, and Windows system-proxy chaining.

## Remote tasks

```powershell
multiagentor-cli task create --name <name> --browser-id <browserId> --script-id <scriptId> [--type local] [--script-context <json> | --script-context-file <path>]
multiagentor-cli task create --file <json> [--script-context <json> | --script-context-file <path>]
multiagentor-cli task create-batch --file <tasks.json>
multiagentor-cli task update --id <taskId> --name <name> --browser-id <browserId> --script-id <scriptId> [--type local] [--script-context <json> | --script-context-file <path>]
multiagentor-cli task update --id <taskId> --file <json> [--script-context <json> | --script-context-file <path>]
multiagentor-cli --json task list [--page 1] [--size 20]
multiagentor-cli task get --id <taskId> [--full]
multiagentor-cli task refresh --id <taskId> [--script-context <json> | --script-context-file <path>]
multiagentor-cli task delete --id <taskId>
```

Create/update/refresh manage remote tasks and cache server-generated runnable payloads. Batch creation is sequential, stops at the first error, and does not roll back earlier successes. Read [task-workflows.md](task-workflows.md).

## Local execution

```powershell
multiagentor-cli run start --task-id <taskId> [--script-context <json> | --script-context-file <path>] [--executor-command <command>]
multiagentor-cli run execute --task-file <path|-> [--environment-id <id>] [--executor-command <command>]
multiagentor-cli --json run list --task-id <taskId> [--page 1] [--size 20]
multiagentor-cli run get --run-id <runId> [--full]
multiagentor-cli run logs --run-id <runId>
multiagentor-cli run cancel --run-id <runId>
```

`run execute` creates no remote task or SQLite task/run record. Use `--environment-id` when it must reuse and lock a persistent Profile. Read [run-supervision.md](run-supervision.md) before starting any run.

## Paths

`<multiagentor-data>` defaults to `%APPDATA%\multiagentor` on Windows and `~/Library/Application Support/multiagentor` on macOS unless `MULTIAGENTOR_HOME` overrides it.

Task runs normally contain:

```text
<multiagentor-data>/tasks/<taskId>/runs/<runId>/
  task.json
  lifecycle.jsonl
  stdout.log
  stderr.log
  script-core.log
```

Direct runs use `<multiagentor-data>/direct-runs/<runId>/`.
