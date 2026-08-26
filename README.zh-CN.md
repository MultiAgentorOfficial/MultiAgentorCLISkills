# MultiAgentor CLI Skills

> 版本与自检：Skill 与 CLI 使用独立版本。Skill 版本记录在 `skills/multiagentor/VERSION`，CLI 版本以 npm 的 `multiagentor-cli@latest` 为准。每个新的 MultiAgentor 工作流开始时会自检关键文件并检查官方 GitHub Skill 版本；发现新版或普通安装不完整时，直接通过干净 Git 工作区的 `pull --ff-only`，或经过身份/版本校验的 GitHub 压缩包备份、修复并原子替换。Skill 更新后必须新建 Codex/WorkBuddy 任务。随后检查 npm CLI，版本落后时直接升级并验证 `--help`。不会覆盖有本地修改的 Git 工作区，也不会擅自改变离线 bundle、固定版本或自定义执行器的来源。

> 浏览器环境与重复运行：创建新浏览器环境前必须询问是否设置代理，并根据实时 CLI 帮助使用内联代理或后续环境代理配置。支持把浏览器扩展导出的 Cookie JSON 以 merge/replace 模式导入固定本地 Profile，也可通过 `browser launch` 打开服务端环境配置对应的本地浏览器并等待关闭。任务重新由服务端创建和管理，生成的 environment、脚本、代理和执行 payload 缓存在本地；批量创建遇错即停且不会回滚此前成功项。Windows 可自动把受支持的无认证 HTTP 系统代理作为任务代理之前的前置链路。等待任务完成并读取结果后，Agent 会额外生成一段可复制的重复运行提示词，其中不包含旧 run ID、Cookie、密码、Token、代理凭据或临时日志路径。

> 平台支持：当前 npm 包支持 Windows x64 与 Apple Silicon macOS（`darwin-arm64`）。Intel Mac、Windows ARM64 和 Linux 暂不支持本地任务执行；skill 会先检查系统与架构，不会尝试不受支持的原生运行时。

在 Apple Silicon macOS 上手动安装 CLI：

```bash
node --version
npm --version
npm install --global multiagentor-cli@latest
multiagentor-cli --help
```

如果没有 Node.js/npm，skill 会运行 `scripts/bootstrap-portable-cli.sh`：使用 Node 官方索引标签 `osx-arm64-tar` 选择 LTS 版本，但下载文件仍使用官方命名 `node-<version>-darwin-arm64.tar.gz`。校验完成后，将 Node.js 和 CLI 隔离安装到 `~/Library/Application Support/multiagentor/portable-runtime`，不修改系统级 PATH。首次执行 `run start` 或 `run execute` 时，npm JavaScript 启动器会准备并校验 macOS 版 `multi-agentor-script-core` 和 `MultiAgentBrowser.app/Contents/MacOS/MultiAgentBrowser`，全部就绪后才会启动任务。

简体中文 | [English](README.md)

本项目提供可在 Codex 或 WorkBuddy 中使用的 Agent Skill，用于在 Windows 上安装、使用和排查 [MultiAgentor CLI](https://www.npmjs.com/package/multiagentor-cli)。

仓库目前包含 `multiagentor`：它能把自然语言自动化需求转换为安全、可执行的 MultiAgentor CLI 工作流。用户不必记忆脚本 ID、浏览器 ID 或大量命令参数，Codex 或 WorkBuddy 会先发现真实候选项，再协助创建任务、运行 RPA、检查日志并定位故障。

## 技能能力

- 安装或选择一种稳定的 `multiagentor-cli` 调用方式。
- 引导 OAuth 登录并检查配置。
- 在询问 ID 前发现真实的脚本、浏览器、任务和运行记录。
- 优先搜索个人脚本（`script my`），没有合适结果时自动回退到完整市场（`script list`）。
- 创建任务前读取脚本参数元数据。
- 在 PowerShell 中使用更可靠的 JSON 文件传递自定义参数。
- 创建、运行、检查、取消和排查本地 RPA 运行。
- 在删除数据或可能产生重复外部操作前请求确认。

该技能为 Codex 或 WorkBuddy 提供操作规范，真正执行自动化的是 MultiAgentor CLI。安装技能时**不会**立即安装 CLI 或浏览器运行时。

入口采用渐进披露结构：`SKILL.md` 只保留意图路由和所有工作流共享的硬约束；安装、浏览器、任务、运行监督和故障诊断分别放在按需读取的引用文件中。以后新增功能应优先写入所属引用；只有新增顶层意图、改变路由或增加全局不变量时才修改入口文件。

## 仓库结构

```text
skills/
└── multiagentor/
    ├── SKILL.md                     # 简洁的意图路由与全局约束
    ├── agents/
    │   └── openai.yaml              # Codex 界面元数据
    ├── scripts/
    │   └── bootstrap-portable-cli.ps1 # 便携 Node.js 与 CLI 引导脚本
    ├── references/
    │   ├── installation-and-updates.md # 安装、更新、运行时就绪
    │   ├── browser-workflows.md        # 浏览器、Cookie、代理、Profile
    │   ├── task-workflows.md           # 脚本发现与远端任务
    │   ├── run-supervision.md          # 等待、结果与重复提示词
    │   ├── troubleshooting.md           # 故障诊断与变更安全
    │   └── command-reference.md         # 精简命令形式
    └── evals/
        └── evals.json               # 行为评测用例
```

## 环境要求

- 支持 Skills 的 Codex 或 WorkBuddy。
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

## 在 WorkBuddy 中安装

### 方式一：让 WorkBuddy 从 GitHub 直接安装（推荐）

在 WorkBuddy 任务中输入：

```text
请从下面的 GitHub 目录安装并启用 MultiAgentor Skill。安装前检查其中的 SKILL.md 和脚本：
https://github.com/MultiAgentorOfficial/MultiAgentorCLISkills/tree/main/skills/multiagentor
```

WorkBuddy 报告安装成功后，确认 `multiagentor` 已出现在已安装技能列表中，然后新建任务并输入：`使用 MultiAgentor 帮我登录。`

### 方式二：上传本地技能包

无法从 GitHub 直接安装时使用此备用方式。WorkBuddy 支持通过“**专家·技能·连接器 → 添加技能 → 上传技能**”导入本地技能包。请只打包 `skills/multiagentor` 目录，确保 ZIP 根目录直接包含 `SKILL.md`，不要上传整个仓库。

使用 PowerShell 生成技能包：

```powershell
git clone https://github.com/MultiAgentorOfficial/MultiAgentorCLISkills.git

$skillSource = Join-Path $PWD 'MultiAgentorCLISkills\skills\multiagentor'
$workBuddyPackage = Join-Path $PWD 'multiagentor-workbuddy.zip'

if (Test-Path -LiteralPath $workBuddyPackage) {
    throw "技能包已存在：$workBuddyPackage"
}

Compress-Archive -Path (Join-Path $skillSource '*') -DestinationPath $workBuddyPackage
```

上传技能包：

1. 在 WorkBuddy 左侧边栏打开“专家·技能·连接器”。
2. 选择“添加技能 → 上传技能”，上传 `multiagentor-workbuddy.zip`。
3. 检查技能来源、脚本内容以及申请的文件、网络和命令执行权限，导入后启用该技能。
4. 新建任务并要求 WorkBuddy 使用 MultiAgentor，例如：`使用 MultiAgentor 帮我登录。`

无论使用哪种方式，启用前都应检查技能来源与申请权限。便携 CLI 引导和首次本地 RPA 运行可能需要授权执行 PowerShell、访问网络，并写入当前用户的 `%APPDATA%`。安装界面及权限说明以[官方 WorkBuddy 技能文档](https://cloud.tencent.com/document/product/1831/134432)为准。

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

如果没有 Node.js 或 npm，技能会按系统选择便携环境引导脚本。Windows x64 使用 `bootstrap-portable-cli.ps1`，安装到 `%APPDATA%\multiagentor\portable-runtime`；Apple Silicon macOS 使用 `bootstrap-portable-cli.sh`，安装到 `~/Library/Application Support/multiagentor/portable-runtime`。两者都从 Node.js 官方源下载 LTS 运行时、完成 SHA-256 校验，不修改系统级 PATH。

npm 安装完成和本地运行环境就绪是两个阶段。在首次通过正确的 npm 启动器执行 `run start`、`run execute`、`browser cookie-import` 或 `browser launch` 并需要本地浏览器时，JavaScript 启动器会校验并安装 script core、选择并下载对应平台的浏览器 ZIP、校验大小与 SHA-256、原子解压，并在 macOS 上设置执行权限；全部就绪后才继续。不要直接运行 `dist/<platform>/` 下的原生 CLI，否则会绕过这道就绪检查。

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

发布任何 Skill 修改时必须同步提升 `skills/multiagentor/VERSION` 的 SemVer；如果内容变化但版本号未变化，已安装 Skill 无法发现该更新。

欢迎提交 Issue 和 Pull Request。修改技能时请遵循以下原则：

1. `SKILL.md` 主要描述决策逻辑和工作流规则。
2. 详细命令语法放在 `references/command-reference.md`。
3. 行为发生变化时，在 `evals/evals.json` 中新增或更新评测用例。
4. 根据当前 `multiagentor-cli --help` 输出校验命令。
5. 不要提交令牌、Cookie、密码、任务载荷或本地日志数据。

## 开源许可证

本项目基于 [MIT License](LICENSE) 开源。
