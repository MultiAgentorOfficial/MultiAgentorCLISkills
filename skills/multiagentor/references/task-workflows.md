# Script discovery and remote task workflows

Read this reference when selecting scripts, resolving parameters, creating/updating/refreshing/deleting tasks, importing a task batch, or migrating an incompatible pure-local task. Read [browser-workflows.md](browser-workflows.md) first when a new task has no resolved browser ID.

## Discover scripts

After the browser ID is resolved:

1. Search authenticated scripts with `--json script my` using the user's business terms.
2. If no suitable personal result exists, automatically repeat with `--json script list` against the full market and tell the user about the fallback.
3. Use `script categories` to discover valid category labels when needed.
4. Rank real results by name, description/category, observed recency/popularity, then simplicity. Show at most three candidates with exact IDs.
5. A market candidate may proceed directly; do not require it to also appear in `script my`. Treat a real server access error as authoritative.

Never invent a candidate when discovery fails.

## Resolve execution parameters

For the selected script, always run `script execute-detail --id <scriptId>`. Use its `scriptContext`, README, defaults, and constraints.

Summarize each non-secret parameter name, default/current value, required state, and meaningful constraint. Then give the user a choice:

1. Use script defaults — omit context flags.
2. Customize parameters — recommend this when the user described a specific target.
3. View parameter explanations before deciding.

If no configurable context exists, say so and ask whether to continue. For custom context:

- Preserve valid user values and all required defaults.
- Turn enums and booleans into concrete choices; show numeric ranges.
- Do not guess unknown fields; use the README description.
- Never echo or persist secrets in reusable artifacts.
- Prefer a complete UTF-8 `--script-context-file`; validate a top-level object and preserve complete `options`/`vars` structure.

Omitting context uses defaults; explicit `{}` clears them. For an existing task, distinguish saved/default context, one-run override via `run start --script-context-file`, and a saved change via update/refresh.

## Create a task

Before mutation, show browser, script, task name, context mode/parameters, and execution behavior. Offer: create and run now, create only, or return to modify.

Use current live help. The remote create flow uses task name, browser ID, script ID, optional type, and optional context. Create/update call the remote API; the server generates environment, script, proxy, and runnable payload, which the CLI caches locally. Parse the returned task ID rather than asking the user to copy it.

Run only when the user chose immediate execution. Otherwise report the ID and exact later `run start` command.

## Update and refresh

Use live help for supported update/file forms. A reusable context change should cause the remote task payload to be regenerated and cached. Refresh reloads the current remote task payload, optionally with supported context behavior.

Do not assume `task list` alone contains a runnable payload. Use `task get --id <id> --full` when execution or migration depends on cached detail.

## Batch creation

Inspect live `task create-batch --help` for the current JSON schema. This operation creates remote tasks sequentially and stops at the first error. It is not atomic:

- Earlier successful tasks remain created and cached.
- The failing item is reported.
- Later items are not attempted.

Explain this before execution. On failure, report successful task IDs, the first failure, and unattempted items. Never promise rollback.

## Transitional pure-local task migration

A pure-local task created by the transitional local-task release is incompatible with the current remote model. Confirm with `task get --full`, then rediscover/confirm browser ID, script ID, name, and context. Show the normal creation summary and create a new remote task.

Report the old-to-new ID mapping. Do not delete the old task automatically and do not claim it can be refreshed in place.

## Delete

Before `task delete`, show the exact task ID and explain that it deletes the remote task plus local mirror, runs, and logs after active-run checks. Require explicit confirmation.

## Command construction

- Put global `--json` before the command.
- Use native shell quoting; do not mix PowerShell and POSIX syntax.
- Prefer UTF-8 files for non-ASCII JSON and context. In Windows PowerShell 5.1, use `--task-file` rather than stdin; if stdin is unavoidable set UTF-8 output encoding first.
- Parse JSON with a real parser, not formatted-table scraping.
- `run execute` creates no reusable remote task or SQLite run record; do not use it when the user expects either.
