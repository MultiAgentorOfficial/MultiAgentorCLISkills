# MultiAgentor CLI Skills

[简体中文](README.zh-CN.md) | English

Agent skills for installing, using, and troubleshooting [MultiAgentor CLI](https://www.npmjs.com/package/multiagentor-cli) on Windows x64 and Apple Silicon macOS with Codex or WorkBuddy.

This repository currently contains `multiagentor`, a reusable agent skill that turns a natural-language automation request into a safe MultiAgentor CLI workflow. It can help discover scripts and browser environments, create and run tasks, inspect logs, and diagnose failures without requiring users to memorize IDs or command flags.

## What the skill does

- Installs or selects one stable `multiagentor-cli` invocation.
- Checks the skill's GitHub SemVer and the CLI's npm `latest` version before a workflow, then updates supported installations automatically.
- Guides OAuth login and configuration checks.
- Discovers real script, browser, task, and run candidates before asking for IDs.
- Searches personal scripts first (`script my`) and falls back to the full market (`script list`) when needed.
- Reads a script's parameter metadata before creating a task.
- Uses shell-safe UTF-8 JSON files for custom execution parameters.
- Creates, runs, inspects, cancels, and troubleshoots local RPA runs.
- Requests confirmation before destructive or potentially duplicative actions.

The skill guides Codex or WorkBuddy; the CLI performs the actual automation. Installing the skill does **not** install the CLI or browser runtime immediately.

## Repository structure

```text
skills/
└── multiagentor/
    ├── SKILL.md                     # Main agent instructions
    ├── agents/
    │   └── openai.yaml              # Codex UI metadata
    ├── scripts/
    │   ├── bootstrap-portable-cli.ps1 # Windows portable Node.js and CLI bootstrap
    │   ├── bootstrap-portable-cli.sh  # Apple Silicon macOS portable bootstrap
    │   ├── update-skill.ps1/.sh       # GitHub skill version check and replacement
    │   └── update-cli.ps1/.sh         # npm global CLI version update
    ├── VERSION                         # Independent skill SemVer
    ├── references/
    │   └── command-reference.md     # CLI command reference
    └── evals/
        └── evals.json               # Behavior evaluation cases
```

## Requirements

- Codex or WorkBuddy with skill support.
- Windows x64 with PowerShell, or Apple Silicon macOS with a POSIX shell. Intel macOS is not supported by the current npm package.
- Node.js 18 or newer and npm when already available. If they are missing, the skill can bootstrap an isolated portable runtime automatically.
- A MultiAgentor account and access to the scripts/browser environments used by your task.

## Install in Codex

### Option 1: Ask Codex to install from GitHub

In Codex, enter:

```text
Use $skill-installer to install the skill from:
https://github.com/MultiAgentorOfficial/MultiAgentorCLISkills/tree/main/skills/multiagentor
```

Start a new Codex task after installation so the new skill is discovered.

### Option 2: Install manually with PowerShell

```powershell
git clone https://github.com/MultiAgentorOfficial/MultiAgentorCLISkills.git

$codexHome = if ($env:CODEX_HOME) {
    $env:CODEX_HOME
} else {
    Join-Path $env:USERPROFILE '.codex'
}
$source = Join-Path $PWD 'MultiAgentorCLISkills\skills\multiagentor'
$destination = Join-Path $codexHome 'skills\multiagentor'

if (Test-Path $destination) {
    throw "Skill already exists at $destination. Back it up or remove it before reinstalling."
}

New-Item -ItemType Directory -Force (Split-Path $destination) | Out-Null
Copy-Item -Recurse $source $destination
Test-Path (Join-Path $destination 'SKILL.md')
```

The last command should return `True`. Start a new Codex task after installation.

On macOS:

```bash
git clone https://github.com/MultiAgentorOfficial/MultiAgentorCLISkills.git
codex_home=${CODEX_HOME:-"$HOME/.codex"}
destination="$codex_home/skills/multiagentor"
test ! -e "$destination" || { echo "Skill already exists: $destination" >&2; exit 1; }
mkdir -p "$codex_home/skills"
cp -R MultiAgentorCLISkills/skills/multiagentor "$destination"
test -f "$destination/SKILL.md"
```

## Install in WorkBuddy

### Option 1: Ask WorkBuddy to install directly from GitHub (recommended)

Paste this into a WorkBuddy task:

```text
Install and enable the MultiAgentor skill from this GitHub directory. Review its SKILL.md and scripts before installation:
https://github.com/MultiAgentorOfficial/MultiAgentorCLISkills/tree/main/skills/multiagentor
```

After WorkBuddy reports success, confirm that `multiagentor` appears in the installed skills list, then start a new task and ask: `Use MultiAgentor to help me sign in.`

### Option 2: Upload a local package

Use this fallback when direct GitHub installation is unavailable. WorkBuddy supports importing a local skill package from **Experts · Skills · Connectors → Add Skill → Upload Skill**. Package only the `skills/multiagentor` directory so `SKILL.md` is at the ZIP root; do not upload the entire repository.

Create the package with PowerShell:

```powershell
git clone https://github.com/MultiAgentorOfficial/MultiAgentorCLISkills.git

$skillSource = Join-Path $PWD 'MultiAgentorCLISkills\skills\multiagentor'
$workBuddyPackage = Join-Path $PWD 'multiagentor-workbuddy.zip'

if (Test-Path -LiteralPath $workBuddyPackage) {
    throw "Package already exists: $workBuddyPackage"
}

Compress-Archive -Path (Join-Path $skillSource '*') -DestinationPath $workBuddyPackage
```

Upload it:

1. Open **Experts · Skills · Connectors** in the WorkBuddy sidebar.
2. Select **Add Skill → Upload Skill** and choose `multiagentor-workbuddy.zip`.
3. Review the source, scripts, requested file/network/command permissions, and enable the skill after import.
4. Start a new task and ask WorkBuddy to use MultiAgentor, for example: `Use MultiAgentor to help me sign in.`

For either method, review the source and requested permissions before enabling the skill. The portable CLI bootstrap and first local RPA run may need permission to execute PowerShell or a POSIX shell, access the network, and write under `%APPDATA%\multiagentor` on Windows or `~/Library/Application Support/multiagentor` on macOS. See the [official WorkBuddy skill documentation](https://cloud.tencent.com/document/product/1831/134432) for the current installation and permission UI.

## Install the MultiAgentor CLI

The skill normally handles this when needed. To install it yourself:

```powershell
node --version
npm --version
npm.cmd install --global multiagentor-cli@latest
multiagentor-cli --help
```

On macOS, use `npm`/`npx` without the `.cmd` suffix:

```bash
node --version
npm --version
npm install --global multiagentor-cli@latest
multiagentor-cli --help
```

The current npm package supports Apple Silicon (`darwin-arm64`) local execution. Do not force-install it under Rosetta on an Intel Mac: the package does not publish a `darwin-x64` runtime.

If a global installation is unavailable, use the non-interactive npm launcher consistently:

```powershell
npx.cmd --yes multiagentor-cli@latest --help
```

If Node.js or npm is unavailable, the skill automatically selects its OS-specific portable bootstrap. Windows x64 uses the verified Node.js ZIP under `%APPDATA%\multiagentor\portable-runtime`; Apple Silicon macOS uses the verified `darwin-arm64` tarball under `~/Library/Application Support/multiagentor/portable-runtime`. Neither changes the machine-wide PATH or installs Node.js system-wide.

npm installation and local runtime readiness are separate stages. The npm package contains the native CLI and `multi-agentor-script-core` for each published platform key, but not the browser. On the first correctly npm-launched `run start` or `run execute`, the JavaScript launcher installs/verifies script core, selects the platform browser artifact, verifies its size and SHA-256, extracts it atomically, applies executable permissions on macOS, and injects both runtime paths before starting the task. If preparation fails, task execution does not begin. Never run a package-internal native binary under `dist/<platform>/` directly because that bypasses this gate.

## Use the skill

Ask Codex in natural language. For example:

```text
Use $multiagentor to install the CLI and help me sign in.
```

```text
Install MultiAgentor CLI and help me sign in.
```

```text
Find an Amazon product collection script and help me create and run a task.
```

```text
My latest MultiAgentor run failed. Inspect its status and logs and explain the cause.
```

```text
Run task task-123 once with custom parameters, without changing its saved defaults.
```

Codex should discover available choices first. Before task creation, it will show the selected script's configurable parameters and ask whether to use the defaults or customize them.

For a new automation, the guided sequence is: **sign in → choose or create a browser environment → choose a script and its parameters → create a task → run the task**. If the account has no browser environments, Codex will inspect the supported systems and guide you through creating one before script selection.

## Update or uninstall

The skill and CLI use separate versions:

- `skills/multiagentor/VERSION` identifies the skill release.
- npm's `multiagentor-cli@latest` dist-tag identifies the current CLI release.

At the start of each new MultiAgentor workflow, the skill checks its official GitHub `VERSION`. A newer version is pulled with `git pull --ff-only` for a clean checkout, or installed from a validated GitHub archive for a standalone skill directory. Standalone updates retain a timestamped sibling backup and roll back if replacement fails. Dirty Git worktrees are never overwritten.

After a skill replacement, start a new Codex or WorkBuddy task so the new `SKILL.md` is loaded. The same workflow then checks npm-managed CLI installations and installs the exact npm `latest` version when it differs. Portable bootstraps also upgrade their isolated CLI cache. Offline bundles, local tarballs, pinned packages, and custom executors are not silently converted to npm installations.

For older installations that predate automatic updating, reinstall once from the GitHub URL. Future releases can then use the included updater.

If you installed a version named `multiagentor-cli-assistant`, install the new `multiagentor` directory and then remove the old directory after verification. Keeping both directories may cause Codex to discover duplicate skills.

For a manual installation, pull this repository and copy the updated contents of `skills/multiagentor` into the installed skill directory. Start a new Codex task after updating.

To uninstall, remove only the installed `multiagentor` directory from `$CODEX_HOME/skills` (or the default `.codex/skills` directory in the user's home). This does not uninstall the npm CLI or delete its local task data.

## Contributing

Issues and pull requests are welcome. When changing the skill:

1. Keep `SKILL.md` focused on decision-making and workflow rules.
2. Put detailed command syntax in `references/command-reference.md`.
3. Add or update cases in `evals/evals.json` for behavior changes.
4. Increment `skills/multiagentor/VERSION` using SemVer for every published skill change; the updater cannot discover a release whose version was not bumped.
5. Validate commands against the current `multiagentor-cli --help` output.
6. Never include tokens, cookies, passwords, task payloads, or local log data in commits.

## License

This project is released under the [MIT License](LICENSE).
