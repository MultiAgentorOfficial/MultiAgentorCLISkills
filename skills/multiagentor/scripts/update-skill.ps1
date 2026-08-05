[CmdletBinding()]
param(
    [string]$Repository = 'MultiAgentorOfficial/MultiAgentorCLISkills',
    [string]$Ref = 'main',
    [switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Read-SemVer {
    param([Parameter(Mandatory = $true)][string]$Value)
    $trimmed = $Value.Trim()
    if ($trimmed -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$') {
        throw "Invalid skill version: $trimmed"
    }
    return [version]$trimmed
}

function Write-Result {
    param([string]$Current, [string]$Latest, [bool]$Updated, [string]$Method, [string]$Backup = '')
    [ordered]@{
        current_version = $Current
        latest_version = $Latest
        updated = $Updated
        method = $Method
        backup_path = $Backup
        restart_required = $Updated
    } | ConvertTo-Json -Compress
}

$skillRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$versionFile = Join-Path $skillRoot 'VERSION'
if (-not (Test-Path -LiteralPath $versionFile)) { throw "Missing skill VERSION: $versionFile" }
$currentText = (Get-Content -Raw -LiteralPath $versionFile).Trim()
$current = Read-SemVer $currentText
$encodedRef = [Uri]::EscapeDataString($Ref)
$versionUrl = "https://raw.githubusercontent.com/$Repository/$encodedRef/skills/multiagentor/VERSION"
$latestText = (Invoke-RestMethod -UseBasicParsing -Headers @{ 'User-Agent' = 'multiagentor-skill-updater' } -Uri $versionUrl).Trim()
$latest = Read-SemVer $latestText

if ($latest -le $current) {
    Write-Result $currentText $latestText $false 'none'
    exit 0
}
if ($CheckOnly) {
    Write-Result $currentText $latestText $false 'available'
    exit 0
}

$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    $worktree = (& $git.Source -C $skillRoot rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -eq 0 -and $worktree) {
        $origin = ((& $git.Source -C $worktree remote get-url origin) | Select-Object -First 1).Trim()
        if ($LASTEXITCODE -ne 0 -or
            $origin -notmatch '^(https://github\.com/|git@github\.com:|ssh://git@github\.com/|git://github\.com/)MultiAgentorOfficial/MultiAgentorCLISkills(?:\.git)?/?$') {
            throw "A newer official skill exists, but this Git worktree origin is not the official repository: $origin"
        }
        $dirty = (& $git.Source -C $worktree status --porcelain)
        if ($LASTEXITCODE -ne 0) { throw 'Failed to inspect the skill Git worktree.' }
        if ($dirty) { throw "A newer skill exists, but the Git worktree has local changes: $worktree" }
        & $git.Source -C $worktree pull --ff-only origin $Ref
        if ($LASTEXITCODE -ne 0) { throw 'git pull --ff-only failed; the skill was not modified.' }
        $installed = (Get-Content -Raw -LiteralPath $versionFile).Trim()
        if ((Read-SemVer $installed) -lt $latest) { throw "Git pull completed but VERSION is still $installed (expected at least $latestText)." }
        Write-Result $currentText $installed $true 'git-ff-only'
        exit 0
    }
}

$parent = Split-Path $skillRoot -Parent
$stamp = Get-Date -Format 'yyyyMMddHHmmss'
$temporary = Join-Path $parent ".multiagentor-update-$stamp-$([guid]::NewGuid().ToString('N'))"
$staged = Join-Path $parent ".multiagentor-staged-$stamp-$([guid]::NewGuid().ToString('N'))"
$backup = Join-Path $parent "multiagentor.backup-$currentText-$stamp"
New-Item -ItemType Directory -Path $temporary | Out-Null

try {
    $archive = Join-Path $temporary 'repository.zip'
    $archiveUrl = "https://github.com/$Repository/archive/refs/heads/$encodedRef.zip"
    Invoke-WebRequest -UseBasicParsing -Headers @{ 'User-Agent' = 'multiagentor-skill-updater' } -Uri $archiveUrl -OutFile $archive
    Expand-Archive -LiteralPath $archive -DestinationPath (Join-Path $temporary 'extract')
    $source = Get-ChildItem -LiteralPath (Join-Path $temporary 'extract') -Directory |
        ForEach-Object { Join-Path $_.FullName 'skills\multiagentor' } |
        Where-Object { Test-Path -LiteralPath (Join-Path $_ 'SKILL.md') } |
        Select-Object -First 1
    if (-not $source) { throw 'Downloaded archive does not contain skills/multiagentor/SKILL.md.' }
    $archiveVersion = (Get-Content -Raw -LiteralPath (Join-Path $source 'VERSION')).Trim()
    if ((Read-SemVer $archiveVersion) -lt $latest) { throw "Archive version $archiveVersion is older than advertised $latestText." }
    $frontmatter = Get-Content -Raw -LiteralPath (Join-Path $source 'SKILL.md')
    if ($frontmatter -notmatch '(?m)^name:\s*multiagentor\s*$') { throw 'Downloaded skill identity validation failed.' }
    Copy-Item -LiteralPath $source -Destination $staged -Recurse
    Move-Item -LiteralPath $skillRoot -Destination $backup
    try {
        Move-Item -LiteralPath $staged -Destination $skillRoot
    } catch {
        if (-not (Test-Path -LiteralPath $skillRoot) -and (Test-Path -LiteralPath $backup)) {
            Move-Item -LiteralPath $backup -Destination $skillRoot
        }
        throw
    }
    Write-Result $currentText $archiveVersion $true 'github-archive' $backup
} finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
    if (Test-Path -LiteralPath $staged) { Remove-Item -LiteralPath $staged -Recurse -Force }
}
