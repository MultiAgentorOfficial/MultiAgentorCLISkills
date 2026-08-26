---
name: multiagentor
description: "Install, update, guide, and operate MultiAgentor CLI on Windows and Apple Silicon macOS for authentication, managed browsers, Cookies, proxies, script discovery, remote tasks, supervised execution, result collection, and diagnosis. Use when a user asks to install or use multiagentor-cli, prepare a persistent browser profile, create or run an RPA task, repeat a completed task, or troubleshoot MultiAgentor."
---

# MultiAgentor

Turn the user's goal into a guided MultiAgentor workflow. Discover real choices, recommend briefly, and ask only for missing, ambiguous, or consequential input.

## Start every workflow

1. Restate the intended outcome in one sentence.
2. Read [installation-and-updates.md](references/installation-and-updates.md) and run the Skill update gate exactly once. If the Skill updates, stop and ask the user to start a new Agent task so the new instructions load.
3. Update/bootstrap the CLI, resolve one stable launcher, run `version` when exposed plus `--help`, and treat live help as authoritative.
4. Authenticate before protected discovery. Use `auth oauth` when login is requested, no usable token exists, or discovery reports authentication failure; wait for authorization.
5. For a new automation, preserve this order: **login → browser environment → script and parameters → remote task creation → run**.

## Load only the reference needed

Do not load every reference by default. Read the smallest set matching the current intent:

| Intent | Required reference |
| --- | --- |
| Install, update, platform support, launcher, runtime preparation | [installation-and-updates.md](references/installation-and-updates.md) |
| Choose/create browser, Cookie import, proxy, Profile, manual launch | [browser-workflows.md](references/browser-workflows.md) |
| Discover scripts, parameters, task CRUD/batch/migration | [task-workflows.md](references/task-workflows.md) |
| Start, wait, monitor, cancel, collect results, repeat prompt | [run-supervision.md](references/run-supervision.md) |
| Diagnose failure, security restriction, risky retry, destructive action | [troubleshooting.md](references/troubleshooting.md) |
| Assemble an exact CLI command | [command-reference.md](references/command-reference.md), plus the relevant workflow reference |

Examples:

- A version question needs installation/update guidance, not task or browser workflow detail.
- Cookie import needs browser guidance and runtime readiness, not script/task creation guidance.
- Starting an existing task needs run supervision and runtime readiness; load task workflows only if task selection, context, or migration is unresolved.
- A failed run needs troubleshooting and run supervision; add installation guidance only for launcher/runtime failures.

## Guided choices

For a new task, use **discover → summarize → recommend → ask → act → report** at these checkpoints:

1. Existing browser environment or create one.
2. Proxy mode for a new environment.
3. Optional Cookie/profile preparation when a saved login is needed.
4. Up to three real script candidates.
5. Script defaults, custom parameters, or parameter explanation.
6. Create-and-run, create-only, or return to modify.

Put the recommended option first and pair exact IDs with human-readable names. Do not ask for information available from read-only discovery, repeat a resolved choice, invent IDs/candidates, or mutate past a required choice point.

## Universal execution invariants

- Preserve the resolved npm shim, npx prefix, portable launcher, or verified bundle launcher for the whole workflow. Never invoke a package-internal native binary directly.
- npm installation and browser runtime readiness are separate. Local browser operations must pass the JavaScript launcher's blocking script-core/browser preparation gate.
- Each browser environment reuses one fixed local UserData Profile. The same environment cannot run concurrently; different environments may.
- Cookie contents, tokens, passwords, proxy credentials, authorization headers, and sensitive inputs must never appear in responses, Agent-created logs, task artifacts, repeat prompts, or commits.
- Starting is not completing. Unless the user explicitly requests background/start-only behavior, keep the Agent session active to terminal state, read actual result contents, and answer the original goal.
- After a waited run, provide a safe copyable repeat-run prompt without old run IDs, secrets, or transient paths.
- Ask immediately before destructive/account mutations or a retry that may duplicate an external side effect. Read [troubleshooting.md](references/troubleshooting.md) for exact confirmation boundaries.

## Intent routing

Use read-only discovery before asking for IDs or supported values:

| User goal | Route |
| --- | --- |
| First use or login | installation check → `auth oauth` |
| Create and run an automation | browser workflow → task workflow → run supervision |
| Browse scripts only | task workflow; stop before task creation |
| Import Cookies or prepare login | browser workflow |
| Open managed browser manually | browser workflow; wait until it closes |
| Run existing task | run supervision; add task workflow when selection/context/migration is needed |
| Run assembled task JSON directly | run supervision using `run execute` |
| Inspect progress or results | run supervision |
| Diagnose failure | troubleshooting plus the failing workflow reference |
| Stop, delete, logout, or replace configuration | troubleshooting confirmation rules |

If the operation is unclear, offer 2–3 goal-level choices, such as create-and-run, run-existing, or diagnose-failure. Do not dump the command catalog.

## Response shape

When waiting for a choice, state the current stage and discovery result, show 2–3 concrete options, then ask one concise question.

When acting or handing off, report chosen values/defaults, exact command or execution result, task/run IDs, and one next status/log command. After a waited run, include the actual result summary and artifact path plus the safe repeat-run prompt.

## Maintain this Skill

Keep this entrypoint concise and readable. When adding future CLI capabilities:

1. Put feature-specific commands, procedures, compatibility notes, examples, and failure handling in the reference matching that feature.
2. Create a new focused reference only when the capability does not fit an existing responsibility.
3. Add to `SKILL.md` only when the change introduces a new top-level intent, changes reference routing, or creates an invariant that applies to every workflow.
4. Link every reference from the routing table or a routed reference; never require all references to be read together.
5. Avoid duplicating detailed instructions between this entrypoint, references, and README files.
6. Keep `SKILL.md` below 180 lines and 18,000 characters. Validate this limit with every Skill release.
