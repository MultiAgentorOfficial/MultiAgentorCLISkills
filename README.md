# MultiAgentor CLI Skills

[简体中文](README.zh-CN.md) | English

Codex skills for installing, using, and troubleshooting [MultiAgentor CLI](https://www.npmjs.com/package/multiagentor-cli) on Windows.

This repository currently contains `multiagentor-cli-assistant`, a reusable Codex skill that turns a natural-language automation request into a safe MultiAgentor CLI workflow. It can help discover scripts and browser environments, create and run tasks, inspect logs, and diagnose failures without requiring users to memorize IDs or command flags.

## What the skill does

- Installs or selects one stable `multiagentor-cli` invocation.
- Guides OAuth login and configuration checks.
- Discovers real script, browser, task, and run candidates before asking for IDs.
- Reads a script's parameter metadata before creating a task.
- Uses PowerShell-safe JSON files for custom execution parameters.
- Creates, runs, inspects, cancels, and troubleshoots local RPA runs.
- Requests confirmation before destructive or potentially duplicative actions.

The skill is guidance for Codex; the CLI performs the actual automation. Installing the skill does **not** install the CLI or browser runtime immediately.

## Repository structure

```text
skills/
└── multiagentor-cli-assistant/
    ├── SKILL.md                     # Main agent instructions
    ├── agents/
    │   └── openai.yaml              # Codex UI metadata
    ├── scripts/
    │   └── bootstrap-portable-cli.ps1 # Portable Node.js and CLI bootstrap
    ├── references/
    │   └── command-reference.md     # CLI command reference
    └── evals/
        └── evals.json               # Behavior evaluation cases
```

## Requirements

- Codex with skill support.
- Windows and PowerShell for the documented CLI workflow.
- Node.js 18 or newer and npm when already available. If they are missing, the skill can bootstrap an isolated portable runtime automatically.
- A MultiAgentor account and access to the scripts/browser environments used by your task.

## Install in Codex

### Option 1: Ask Codex to install from GitHub

In Codex, enter:

```text
Use $skill-installer to install the skill from:
https://github.com/MultiAgentorOfficial/MultiAgentorCLISkills/tree/main/skills/multiagentor-cli-assistant
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
$source = Join-Path $PWD 'MultiAgentorCLISkills\skills\multiagentor-cli-assistant'
$destination = Join-Path $codexHome 'skills\multiagentor-cli-assistant'

if (Test-Path $destination) {
    throw "Skill already exists at $destination. Back it up or remove it before reinstalling."
}

New-Item -ItemType Directory -Force (Split-Path $destination) | Out-Null
Copy-Item -Recurse $source $destination
Test-Path (Join-Path $destination 'SKILL.md')
```

The last command should return `True`. Start a new Codex task after installation.

## Install the MultiAgentor CLI

The skill normally handles this when needed. To install it yourself:

```powershell
node --version
npm --version
npm.cmd install --global multiagentor-cli@latest
multiagentor-cli --help
```

If a global installation is unavailable, use the non-interactive npm launcher consistently:

```powershell
npx.cmd --yes multiagentor-cli@latest --help
```

If Node.js or npm is unavailable, the skill automatically runs its portable bootstrap. It downloads the matching Windows x64/ARM64 Node.js LTS ZIP from the official Node.js distribution, verifies SHA-256, and installs Node.js plus the CLI under `%APPDATA%\multiagentor-cli\portable-runtime`. It does not require an administrator account, change the system PATH, or install Node.js machine-wide.

The first npm-launched `run start` or `run execute` may download and verify the packaged RPA Agent and compatible browser runtime. They are cached under `%APPDATA%\multiagentor-cli\`; regular help, authentication, configuration, and remote CRUD commands do not trigger that download.

## Use the skill

Ask Codex in natural language. For example:

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

## Update or uninstall

To update an installation made by `$skill-installer`, back up or remove the existing `multiagentor-cli-assistant` skill directory and install it again from the GitHub URL. The installer intentionally stops when the destination already exists.

For a manual installation, pull this repository and copy the updated contents of `skills/multiagentor-cli-assistant` into the installed skill directory. Start a new Codex task after updating.

To uninstall, remove only the installed `multiagentor-cli-assistant` directory from `$CODEX_HOME/skills` (or `%USERPROFILE%\.codex\skills`). This does not uninstall the npm CLI or delete its local task data.

## Contributing

Issues and pull requests are welcome. When changing the skill:

1. Keep `SKILL.md` focused on decision-making and workflow rules.
2. Put detailed command syntax in `references/command-reference.md`.
3. Add or update cases in `evals/evals.json` for behavior changes.
4. Validate commands against the current `multiagentor-cli --help` output.
5. Never include tokens, cookies, passwords, task payloads, or local log data in commits.

## License

This project is released under the [MIT License](LICENSE).
