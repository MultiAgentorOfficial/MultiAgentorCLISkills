# Troubleshooting and safety

Read this reference when diagnosing a failed run, runtime preparation, authentication/configuration problem, browser launch failure, or a potentially destructive/risky retry.

## Diagnose with evidence

Resolve the run ID from user input or `run list`, then read `run get --full`, lifecycle logs, and output paths. Inspect `stderr.log` and `script-core.log` when needed.

Classify the failure before recommending a fix:

- CLI, authentication, API, or configuration
- runtime download, script-core compatibility, or browser executable
- invalid task envelope/context or incompatible transitional task
- script-core process failure
- Windows system-proxy or task-proxy startup
- macOS signature, notarization, quarantine, or executable permission
- target website/script behavior

Redact tokens, Cookies, authorization headers, passwords, proxy credentials, and sensitive script input.

## Clean-machine failures

For browser-executable failures at 0%, inspect OS/architecture and launcher provenance. An npm package with `bin/multiagentor-cli.js` must be reached through its npm shim, npx, or portable wrapper. If an internal native binary was used, preserve the remote task ID, correct the launcher, and do not create a replacement task.

Do not claim an npm tarball contains the browser or confuse it with a full offline bundle. Report verified artifact type, platform key, data root, script-core path, and browser path without exposing secrets.

If runtime readiness fails, follow [installation-and-updates.md](installation-and-updates.md). Do not bypass checksums or required script-core capabilities.

## Proxy startup failures

An unsupported proxy type must fail before browser startup. On Windows, an unsupported or unreachable detected system front proxy must also fail safely and must not silently fall back to direct access. Distinguish the system front chain from the effective task proxy and protect credentials.

## macOS launch restrictions

Inspect executable mode and use read-only checks:

```bash
codesign --verify --deep --strict <path>
spctl --assess --type execute <path>
```

Report the failing component. Do not globally disable Gatekeeper or recursively strip quarantine. Ask before a targeted security-metadata change.

## Retry and mutation safety

Do not rerun automatically when it may duplicate submissions, purchases, messages, uploads, or other external effects. Explain the correction and ask before rerunning.

Require explicit confirmation immediately before:

- `task delete` (remote task plus local mirror/runs/logs)
- `auth logout` (clears local token)
- `run cancel`, unless already explicitly requested for that run
- `config set` or proxy clear/set when replacing a known working configuration
- any retry with repeatable external side effects

Show exact target ID/value and consequence. Never print a bearer token or token fields from `config show`.
