# Browser environments, Cookies, migration bundles, profiles, and proxies

Read this reference when choosing/creating a browser environment, importing/exporting Cookies or migration bundles, configuring proxies, or opening a managed browser manually. Also read [installation-and-updates.md](installation-and-updates.md) when local runtime preparation is involved.

## Choose before selecting a script

For every new task, resolve the browser immediately after authentication:

1. Run `--json browser list`.
2. If environments exist, offer at most three real candidates with names and IDs, plus the option to create a new environment.
3. If none exist, say so, run `--json browser systems`, and offer valid OS/version choices. Do not request an impossible browser ID or proceed to script selection.
4. Before creation, explicitly ask whether to use a proxy. Inspect live `browser quick-create --help`; when available, `--proxy-mode no` creates without proxy and `--proxy-mode merge` accepts inline HTTP/SOCKS5 settings.
5. Show selected name, OS/version, and proxy mode before creation unless the user already specified them. Parse the returned ID; never invent one.

Never request proxy credentials until a supported path is identified. Do not print, log, place in task context, or include credentials in repeat prompts.

## Proxy scopes and precedence

Keep these mechanisms distinct:

- `browser quick-create` / `browser proxy` configure the remote browser environment.
- `config proxy` configures a local default or environment-specific browser execution proxy.

An environment-specific local proxy replaces the local default for that environment. Without either local setting, preserve the server-generated task proxy. A selected local proxy replaces the complete task proxy immediately before execution. It affects browser traffic only, not OAuth, API, npm, or runtime downloads.

Before changing or clearing a working local proxy, show its scope and consequence and ask for confirmation. `config proxy show` masks passwords; never reveal stored credentials.

## Persistent UserData Profile

Each environment ID maps to one fixed local UserData Profile. Later tasks and manual launches using that ID reuse its Cookies and browser state. Different data roots or login identities remain isolated.

The same environment cannot run concurrently because it owns one profile lock. Different environment IDs may run concurrently. For `run execute`, pass `--environment-id` when persistent profile reuse and locking are required.

## Cookie import

When the user supplies browser-extension Cookie JSON:

1. Inspect `browser cookie-import --help` and validate that the path exists and contains a UTF-8 JSON array within current limits.
2. Ask for `merge` or `replace` unless already specified. Recommend `merge`: it preserves unrelated Cookies. Explain that `replace` clears all existing profile Cookies first.
3. Run through the resolved npm/portable launcher:

```text
multiagentor-cli browser cookie-import --id <browserId> --file <cookies.json> [--mode merge|replace]
```

Let the launcher prepare the current script core and browser runtime. Cookie contents remain in the current machine's Profile; they are not uploaded or stored in the CLI database. Never print them or copy them into task JSON, logs, repeat prompts, or commits.

## Browser migration bundles

Use the migration commands when the user wants to move a complete browser environment between machines or data roots:

```text
multiagentor-cli browser export --id <browserId> --file <bundle.json> [--force]
multiagentor-cli browser import --file <bundle.json>
```

The bundle contains server environment configuration plus local Cookie, proxy, and account information. Treat it as a plaintext sensitive secret file:

- Before export, show the exact browser ID and destination path. If the destination exists, require explicit confirmation before adding `--force`; never overwrite an existing bundle silently.
- Before import, validate that the path exists and is the intended UTF-8 bundle format using current `browser import --help`. Explain that import can create/restore browser configuration and local sensitive state, then ask for confirmation if it changes an existing environment or profile.
- Keep the bundle out of commits, chat messages, logs, task JSON, repeat-run prompts, shared folders, and unencrypted backup locations. Do not inspect or echo raw Cookies, proxy credentials, or account fields; report only metadata needed to confirm the operation.
- Run both commands through the resolved npm/portable launcher and allow runtime preparation when local browser state is accessed. After import, rediscover the resulting browser environment and use its real ID for later tasks.
- The existing `browser cookie-import --id <id> --file <cookies.json> [--mode merge|replace]` Cookie-array format remains supported. Do not pass a Cookie array to `browser import` or treat a migration bundle as a plain Cookie array.

Migration bundles are for transfer only; they do not make sensitive values safe to share. Delete or securely destroy an exported bundle when the transfer is complete, after confirming the user wants it removed.

## Manual browser launch

Use `browser launch --id <browserId>` when the user wants to log in or operate manually with the server environment configuration.

Confirm the environment is real, invoke it through the resolved launcher, and wait for runtime preparation. Keep the Agent session active until the user closes the browser and the command exits; opening the window is not completion.

## Windows system-proxy front chain

On Windows, task browser startup and manual launch may automatically detect a supported unauthenticated HTTP system proxy. No extra CLI flag is required.

When both system and effective task proxies exist, traffic flows through the system proxy first and the task proxy second. Unsupported proxy types or an unreachable system proxy must fail startup safely. Do not invent flags, silently bypass it, or claim fallback to direct access. macOS behavior is unchanged.
