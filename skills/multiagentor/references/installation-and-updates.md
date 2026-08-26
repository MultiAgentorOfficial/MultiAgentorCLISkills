# Installation, updates, and runtime readiness

Read this reference for installation, upgrade, clean-machine bootstrap, platform support, launcher selection, or runtime preparation failures.

## Skill update gate

Treat Skill and CLI versions independently. At the start of each new MultiAgentor workflow, run the installed Skill updater exactly once:

- Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File <skill>/scripts/update-skill.ps1`
- macOS: `sh <skill>/scripts/update-skill.sh`

Require updater JSON `integrity_ok: true`. A clean Git checkout may update only with `git pull --ff-only origin main`; never overwrite a dirty worktree. A standalone installation may be replaced only from the official `MultiAgentorOfficial/MultiAgentorCLISkills` archive after validating `VERSION` and `name: multiagentor`, retaining a timestamped backup and rollback path.

If `updated` and `restart_required` are true, report old/new versions and backup path, then stop. Ask the user to start a new Codex/WorkBuddy task because the loaded instructions are stale. If GitHub cannot be reached, report freshness as unverified; continue offline only when the user already permitted it. Never update while an RPA run is active.

## CLI update gate

After the Skill gate, determine CLI provenance and update before authentication or task work:

- Global npm: run `scripts/update-cli.ps1` or `scripts/update-cli.sh`. It compares the global package with `npm view multiagentor-cli@latest version`, installs the exact resolved version if different, and verifies installation plus help.
- Portable: rerun the platform bootstrap; it updates its isolated npm package.
- npx: retain the full `npx --yes multiagentor-cli@latest` prefix.
- Offline bundle, local `.tgz`, pinned package, or custom executor: report its source/version and do not silently replace it with npm.

When exposed, use `multiagentor-cli version` to report the installed version. Do not infer it from a folder or archive name. Complete all updates before selecting one invocation; never switch launchers midway through a workflow.

## Select an invocation

Detect OS and CPU first. Use current package metadata as authority. Supported published platform keys have included Windows x64 (`win32-x64`) and Apple Silicon macOS (`darwin-arm64`); stop on a platform absent from the inspected package.

Classify supplied artifacts:

- An npm package contains `bin/multiagentor-cli.js`, platform directories under `dist/`, packaged script core, and manifests. Invoke only its npm shim, npx, or a Skill-generated portable launcher. Never invoke `dist/<platform>/multiagentor-cli[.exe]` directly.
- An extracted full offline bundle is different. Verify its root launcher and its own matching script-core/browser instructions; do not treat an npm tarball as a full bundle.

Otherwise locate `multiagentor-cli` (`Get-Command` on Windows, `command -v` on macOS). If Node.js 18+ and npm work, prefer:

```powershell
npm.cmd install --global multiagentor-cli@latest
multiagentor-cli --help
```

If global install or PATH is unavailable, use and retain the entire prefix:

```powershell
npx.cmd --yes multiagentor-cli@latest --help
```

On macOS use `npm`, `npx`, and the same package/tag.

## Portable bootstrap

When Node/npm is missing, outdated, or unusable, run the Skill script for the detected platform. Do not install system-wide Node or modify machine-wide PATH.

Windows x64:

```powershell
$runtime = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File <skill>\scripts\bootstrap-portable-cli.ps1 |
    Select-Object -Last 1 | ConvertFrom-Json
& $runtime.invocation --help
```

Apple Silicon macOS:

```bash
runtime_json=$(sh <skill>/scripts/bootstrap-portable-cli.sh | tail -n 1)
invocation=$(printf '%s' "$runtime_json" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>process.stdout.write(JSON.parse(s).invocation))')
"$invocation" --help
```

The scripts download Node from `nodejs.org`, validate the official checksum, install under the user's MultiAgentor data root, and return a reusable invocation. On Apple Silicon, Node's index selector is `osx-arm64-tar` while the archive remains `node-<version>-darwin-arm64.tar.gz`; do not conflate those names or bypass `SHASUMS256.txt`.

## Blocking runtime-readiness gate

An npm install alone does not prove local browser execution is ready. Preserve the JavaScript launcher for `run start`, `run execute`, `browser cookie-import`, and `browser launch`.

Before spawning the native CLI, the launcher must:

1. Confirm Node 18+, `bin/multiagentor-cli.js`, the platform native CLI, packaged `multi-agentor-script-core`, and `script-core-manifest.json`.
2. Confirm the package/manifest identifies a compatible script core. System-proxy front chaining requires script-core 0.1.3 with capability introduced by commit `8857620`; reject an incompatible core before browser startup.
3. Install/reuse script core under `<multiagentor-data>/runtime/<platform>/versions/<hash>/` and set executable mode on macOS.
4. Honor `MULTIAGENTOR_BROWSER_EXECUTABLE` only when it is an existing absolute compatible executable. Otherwise download the declared browser ZIP, verify size and SHA-256, extract atomically, confirm its declared executable, apply mode `0755` on macOS, and update `browsers/current.json`.
5. Set `MULTIAGENTOR_SCRIPT_CORE_COMMAND` and `MULTIAGENTOR_BROWSER_EXECUTABLE`, then spawn the platform native CLI with the original arguments.

If any preparation stage fails, stop before execution and report platform plus failed stage. Do not bypass the launcher, create a replacement task, substitute ordinary Chrome, or claim a task is running. When no public prepare command exists, readiness is the blocking prefix of the first local-execution command; wait through it.

Data roots default to `%APPDATA%\multiagentor` on Windows and `~/Library/Application Support/multiagentor` on macOS unless `MULTIAGENTOR_HOME` overrides them.
