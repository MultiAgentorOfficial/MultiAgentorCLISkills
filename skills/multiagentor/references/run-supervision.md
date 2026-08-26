# Run supervision, results, and repeat prompts

Read this reference whenever starting, waiting for, monitoring, cancelling, or collecting results from `run start` or `run execute`.

## Default is start and wait

A launched process, created task/run ID, completed runtime preparation, open browser, or first progress update is not completion.

Only an explicit instruction such as “启动后不用等待”, “后台运行”, “只启动”, or “不用等结果” permits returning while active. Do not ask a redundant wait question otherwise, and never switch to no-wait because a run is slow, output is sparse, or a tool times out.

## Monitoring

Prefer the resolved launcher in the foreground. If the host cannot keep one long call open, use its supported hidden/background process mechanism and capture stdout/stderr.

- `run start`: resolve the run ID from output or `--json run list --task-id <taskId>`, then poll `run get --run-id <runId> --full`.
- `run execute`: it has no SQLite task/run record. Supervise the process handle, captured output, and `<multiagentor-data>/direct-runs/<runId>/` directory; do not substitute `run get`.

Continue until the current CLI reports a terminal equivalent of success, failure, or cancellation. Treat queued, preparing, starting, and running as non-terminal. If a tool disconnects or times out, immediately re-read the run/process/log state and continue. A tool timeout is not a run failure.

Give concise progress updates with run ID, state/progress, and material stage changes.

## Result collection

At terminal state, collect results before ending the Agent session:

- `run start`: call `run get --run-id <runId> --full`; inspect complete result/output fields and every exposed artifact path.
- `run execute`: parse its final JSON summary and inspect named artifacts in the direct-run directory.

Prefer structured result JSON or explicit output artifacts. Use `stdout.log` and `script-core.log` only when structured output is absent/incomplete; use lifecycle and `stderr.log` to explain failures.

Read result contents, not just paths. For large data, inspect schema, counts, key findings, and representative records, then provide the full path. Never dump secrets, Cookies, tokens, or excessive raw records. If execution says success but no usable result exists, say so and inspect logs; do not invent output.

Report final status, progress, result summary, and relevant artifact paths.

## Repeat-run prompt

After every waited run and result collection, produce one fenced, copyable natural-language request to `$multiagentor` containing:

- Skill/CLI self-check and update, with restart after a Skill reload.
- Stable task ID and human-readable name.
- Saved/default or one-run context mode and safe effective parameters.
- Instruction to wait for terminal state, read artifacts, and summarize results.
- Confirmation immediately before any repeat that may submit, purchase, message, upload, or otherwise repeat an external side effect.

Exclude old run ID, tokens, Cookies, passwords, proxy credentials, temporary context files, and transient result/log paths. Replace required secrets with “ask me securely before running”. For `run execute`, mention a durable task file only if it will remain available; otherwise ask for the JSON again.

## Explicit start-without-wait

When the user explicitly chooses no-wait, return task ID, run ID when available, last observed state, and exact `run get` / `run logs` commands. Do not call an active state successful. A repeat prompt is optional because results are not yet known.

## Cancellation

Ask for explicit confirmation before `run cancel` unless the user already clearly requested stopping that exact run. Report the target run ID and consequence.
