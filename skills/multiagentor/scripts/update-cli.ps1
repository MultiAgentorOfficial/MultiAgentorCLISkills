[CmdletBinding()]
param([string]$Package = 'multiagentor-cli')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
if (-not $npm) { $npm = Get-Command npm -ErrorAction Stop }

$latestRaw = & $npm.Source view "$Package@latest" version --json
if ($LASTEXITCODE -ne 0) { throw "Failed to resolve $Package latest version from npm." }
$latest = ([string]($latestRaw | ConvertFrom-Json)).Trim()
$listRaw = & $npm.Source list --global $Package --depth=0 --json 2>$null
$installed = ''
if ($LASTEXITCODE -eq 0 -and $listRaw) {
    $list = $listRaw | ConvertFrom-Json
    $dependency = $list.dependencies.$Package
    if ($dependency) { $installed = [string]$dependency.version }
}

$updated = $false
if ($installed -ne $latest) {
    & $npm.Source install --global "$Package@$latest" --no-audit --no-fund
    if ($LASTEXITCODE -ne 0) { throw "Failed to install $Package@$latest globally." }
    $updated = $true
}

$verifiedRaw = & $npm.Source list --global $Package --depth=0 --json
if ($LASTEXITCODE -ne 0) { throw 'Failed to verify the global CLI installation.' }
$verified = [string](($verifiedRaw | ConvertFrom-Json).dependencies.$Package.version)
if ($verified -ne $latest) { throw "CLI verification mismatch: installed $verified, expected $latest." }
$globalPrefix = ((& $npm.Source prefix --global) | Select-Object -Last 1).Trim()
if ($LASTEXITCODE -ne 0 -or -not $globalPrefix) { throw 'Failed to resolve the npm global prefix.' }
$invocation = Join-Path $globalPrefix 'multiagentor-cli.cmd'
if (-not (Test-Path -LiteralPath $invocation)) {
    $command = Get-Command multiagentor-cli -ErrorAction SilentlyContinue
    if (-not $command) { throw "The npm package is installed, but its CLI shim was not found under $globalPrefix or PATH." }
    $invocation = $command.Source
}
& $invocation --help | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Updated MultiAgentor CLI failed its --help check.' }

[ordered]@{
    previous_version = $installed
    latest_version = $latest
    installed_version = $verified
    updated = $updated
    invocation = $invocation
} | ConvertTo-Json -Compress
