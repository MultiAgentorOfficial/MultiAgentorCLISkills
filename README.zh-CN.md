# MultiAgentor CLI Skills

简体中文 | [English](README.md)

本项目提供用于在 Windows 上安装、使用和排查 [MultiAgentor CLI](https://www.npmjs.com/package/multiagentor-cli) 的 Codex 技能。

仓库目前包含 `multiagentor`：它能把自然语言自动化需求转换为安全、可执行的 MultiAgentor CLI 工作流。用户不必记忆脚本 ID、浏览器 ID 或大量命令参数，Codex 会先发现真实候选项，再协助创建任务、运行 RPA、检查日志并定位故障。

## 技能能力

- 安装或选择一种稳定的 `multiagentor-cli` 调用方式。
- 引导 OAuth 登录并检查配置。
- 在询问 ID 前发现真实的脚本、浏览器、任务和运行记录。
- 优先搜索个人脚本（`script my`），没有合适结果时自动回退到完整市场（`script list`）。
- 创建任务前读取脚本参数元数据。
- 在 PowerShell 中使用更可靠的 JSON 文件传递自定义参数。
- 创建、运行、检查、取消和排查本地 RPA 运行。
- 在删除数据或可能产生重复外部操作前请求确认。

该技能为 Codex 提供操作规范，真正执行自动化的是 MultiAgentor CLI。安装技能时**不会**立即安装 CLI 或浏览器运行时。

## 仓库结构

```text
skills/
└── multiagentor/
    ├── SKILL.md                     # 技能主指令
    ├── agents/
    │   └── openai.yaml              # Codex 界面元数据
    ├── scripts/
    │   └── bootstrap-portable-cli.ps1 # 便携 Node.js 与 CLI 引导脚本
    ├── references/
    │   └── command-reference.md     # CLI 命令参考
    └── evals/
        └── evals.json               # 行为评测用例
```

## 环境要求

- 支持 Skills 的 Codex。
- Windows 与 PowerShell（当前 CLI 工作流以此为准）。
- 如果系统已有 Node.js/npm，需要 Node.js 18 或更高版本；如果没有，技能可自动准备隔离的便携运行环境。
- MultiAgentor 账号，以及任务所需脚本和浏览器环境的访问权限。

## 在 Codex 中安装

### 方式一：让 Codex 从 GitHub 安装

在 Codex 中输入：

```text
使用 $skill-installer 安装这个技能：
https://github.com/MultiAgentorOfficial/MultiAgentorCLISkills/tree/main/skills/multiagentor
```

安装完成后新建一个 Codex 任务，让 Codex 发现新技能。

### 方式二：使用 PowerShell 手动安装

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

最后一条命令应返回 `True`。安装完成后请新建一个 Codex 任务。

## 安装 MultiAgentor CLI

实际使用时，技能会在需要时协助完成安装。如需手动安装：

```powershell
node --version
npm --version
npm.cmd install --global multiagentor-cli@latest
multiagentor-cli --help
```

如果无法全局安装，请在后续操作中始终使用非交互式 npm 启动方式：

```powershell
npx.cmd --yes multiagentor-cli@latest --help
```

如果没有 Node.js 或 npm，技能会自动运行便携环境引导脚本：从 Node.js 官方分发源下载匹配 Windows x64/ARM64 的 LTS ZIP，完成 SHA-256 校验后，将 Node.js 和 CLI 安装到 `%APPDATA%\multiagentor-cli\portable-runtime`。整个过程无需管理员权限，不修改系统 PATH，也不会在系统中全局安装 Node.js。

首次通过 npm 启动 `run start` 或 `run execute` 时，CLI 可能会下载并校验配套的 RPA Agent 和兼容浏览器运行时，并缓存到 `%APPDATA%\multiagentor-cli\`。帮助、登录、配置及远程增删改查命令不会触发浏览器下载。

## 使用示例

直接用自然语言向 Codex 描述目标，例如：

```text
使用 $multiagentor 安装 CLI 并帮我登录。
```

```text
安装 MultiAgentor CLI 并帮我登录。
```

```text
查找亚马逊商品采集脚本，帮我创建并运行一个任务。
```

```text
最近一次 MultiAgentor 运行失败了，请检查状态和日志并说明原因。
```

```text
使用自定义参数运行一次 task-123，但不要修改任务中保存的默认参数。
```

Codex 会先发现可用选项。创建任务前，它会展示所选脚本可配置的参数，并让你明确选择使用默认值或自定义参数。

新自动化任务的标准引导顺序为：**登录 → 选择或创建浏览器环境 → 选择脚本及参数 → 创建任务 → 运行任务**。如果账号中没有浏览器环境，Codex 会先读取服务端支持的系统，并引导完成创建，然后才进入脚本选择。

## 更新与卸载

如果通过 `$skill-installer` 安装，请先备份或移除现有的 `multiagentor` 技能目录，再从 GitHub 地址重新安装。安装器发现目标目录已存在时会主动停止，避免覆盖已有内容。

如果以前安装的版本名为 `multiagentor-cli-assistant`，请先安装新的 `multiagentor` 目录，验证后再移除旧目录。保留两个目录可能导致 Codex 同时发现两个重复技能。

如果通过手动方式安装，可先拉取本仓库最新版本，再将 `skills/multiagentor` 中的更新内容复制到已安装目录。更新后请新建一个 Codex 任务。

卸载时，只需移除 `$CODEX_HOME/skills`（或 `%USERPROFILE%\.codex\skills`）下的 `multiagentor` 目录。该操作不会卸载 npm CLI，也不会删除 CLI 的本地任务数据。

## 参与贡献

欢迎提交 Issue 和 Pull Request。修改技能时请遵循以下原则：

1. `SKILL.md` 主要描述决策逻辑和工作流规则。
2. 详细命令语法放在 `references/command-reference.md`。
3. 行为发生变化时，在 `evals/evals.json` 中新增或更新评测用例。
4. 根据当前 `multiagentor-cli --help` 输出校验命令。
5. 不要提交令牌、Cookie、密码、任务载荷或本地日志数据。

## 开源许可证

本项目基于 [MIT License](LICENSE) 开源。
