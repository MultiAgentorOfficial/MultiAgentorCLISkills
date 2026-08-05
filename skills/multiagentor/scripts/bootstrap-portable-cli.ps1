[CmdletBinding()]
param(
    [string]$CacheRoot = (Join-Path $env:APPDATA 'multiagentor\portable-runtime'),
    [string]$NodeIndexUrl = 'https://nodejs.org/dist/index.json',
    [string]$NodeDistBaseUrl = 'https://nodejs.org/dist',
    [string]$CliPackage = 'multiagentor-cli@latest'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Get-NodePlatform {
    $architecture = if ($env:PROCESSOR_ARCHITEW6432) {
        $env:PROCESSOR_ARCHITEW6432
    } else {
        $env:PROCESSOR_ARCHITECTURE
    }

    switch ($architecture.ToUpperInvariant()) {
        'AMD64' { return 'win-x64' }
        default { throw "Unsupported Windows architecture: $architecture. The current MultiAgentor npm package supports Windows x64 only." }
    }
}

function Assert-ChildPath {
    param(
        [Parameter(Mandatory = $true)][string]$Parent,
        [Parameter(Mandatory = $true)][string]$Child
    )

    $parentPath = [System.IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $childPath = [System.IO.Path]::GetFullPath($Child)
    if (-not $childPath.StartsWith($parentPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify a path outside the cache root: $childPath"
    }
}

function Invoke-JsonRequest {
    param([Parameter(Mandatory = $true)][string]$Uri)

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            return Invoke-RestMethod -UseBasicParsing -Uri $Uri -Headers @{ 'User-Agent' = 'multiagentor-cli-bootstrap' }
        } catch {
            if ($attempt -lt 3) {
                Start-Sleep -Seconds $attempt
            }
        }
    }

    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if (-not $curl) {
        throw "Failed to download $Uri after 3 attempts, and curl.exe is unavailable."
    }

    $json = & $curl.Source --fail --silent --show-error --location --retry 3 --retry-all-errors $Uri 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to download $Uri with both PowerShell and curl.exe."
    }
    return $json | ConvertFrom-Json
}

function Invoke-DownloadFile {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$OutFile
    )

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $Uri -Headers @{ 'User-Agent' = 'multiagentor-cli-bootstrap' } -OutFile $OutFile
            return
        } catch {
            if ($attempt -lt 3) {
                Start-Sleep -Seconds $attempt
            }
        }
    }

    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if (-not $curl) {
        throw "Failed to download $Uri after 3 attempts, and curl.exe is unavailable."
    }

    & $curl.Source --fail --silent --show-error --location --retry 3 --retry-all-errors --output $OutFile $Uri 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to download $Uri with both PowerShell and curl.exe."
    }
}

if (-not $env:APPDATA -and -not $PSBoundParameters.ContainsKey('CacheRoot')) {
    throw 'APPDATA is unavailable. Pass -CacheRoot with an explicit writable directory.'
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$platform = Get-NodePlatform
$archiveKind = "$platform-zip"
$cachePath = [System.IO.Path]::GetFullPath($CacheRoot)
New-Item -ItemType Directory -Force -Path $cachePath | Out-Null

$release = $null
$indexFailure = $null
try {
    $index = Invoke-JsonRequest -Uri $NodeIndexUrl
    $release = $index |
        Where-Object {
            $major = [int]$_.version.TrimStart('v').Split('.')[0]
            $_.lts -and $major -ge 18 -and $_.files -contains $archiveKind
        } |
        Select-Object -First 1
} catch {
    $indexFailure = $_
}

if ($release) {
    $version = [string]$release.version
} else {
    $cachedRelease = Get-ChildItem -LiteralPath $cachePath -Directory -Filter "node-v*-$platform" |
        ForEach-Object {
            if ($_.Name -match '^node-v(?<version>\d+\.\d+\.\d+)-') {
                $parsedVersion = [version]$Matches.version
                if ($parsedVersion.Major -ge 18 -and
                    (Test-Path -LiteralPath (Join-Path $_.FullName 'node.exe')) -and
                    (Test-Path -LiteralPath (Join-Path $_.FullName 'npm.cmd'))) {
                    [pscustomobject]@{ Version = $parsedVersion; Directory = $_.FullName }
                }
            }
        } |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $cachedRelease) {
        if ($indexFailure) {
            throw $indexFailure
        }
        throw "No Node.js LTS release >= 18 provides $archiveKind according to $NodeIndexUrl."
    }
    $version = 'v' + $cachedRelease.Version.ToString()
}

$archiveName = "node-$version-$platform.zip"
$nodeDirectory = Join-Path $cachePath "node-$version-$platform"
$nodeExecutable = Join-Path $nodeDirectory 'node.exe'
$npmCommand = Join-Path $nodeDirectory 'npm.cmd'
$nodeDownloaded = $false

if (-not (Test-Path -LiteralPath $nodeExecutable) -or -not (Test-Path -LiteralPath $npmCommand)) {
    $temporaryDirectory = Join-Path $cachePath ('.bootstrap-' + [guid]::NewGuid().ToString('N'))
    Assert-ChildPath -Parent $cachePath -Child $temporaryDirectory
    New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null

    try {
        $archivePath = Join-Path $temporaryDirectory $archiveName
        $checksumsPath = Join-Path $temporaryDirectory 'SHASUMS256.txt'
        $releaseBaseUrl = "$($NodeDistBaseUrl.TrimEnd('/'))/$version"

        Invoke-DownloadFile -Uri "$releaseBaseUrl/SHASUMS256.txt" -OutFile $checksumsPath
        Invoke-DownloadFile -Uri "$releaseBaseUrl/$archiveName" -OutFile $archivePath

        $checksumLine = Get-Content -LiteralPath $checksumsPath |
            Where-Object { $_ -match "^[a-fA-F0-9]{64}\s+$([regex]::Escape($archiveName))$" } |
            Select-Object -First 1
        if (-not $checksumLine) {
            throw "The official checksum list does not contain $archiveName."
        }

        $expectedHash = ($checksumLine -split '\s+')[0].ToUpperInvariant()
        $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash.ToUpperInvariant()
        if ($actualHash -ne $expectedHash) {
            throw "SHA-256 verification failed for $archiveName."
        }

        $extractRoot = Join-Path $temporaryDirectory 'extracted'
        Expand-Archive -LiteralPath $archivePath -DestinationPath $extractRoot
        $extractedDirectory = Join-Path $extractRoot "node-$version-$platform"
        if (-not (Test-Path -LiteralPath (Join-Path $extractedDirectory 'node.exe'))) {
            throw 'The downloaded Node.js archive did not contain node.exe in the expected directory.'
        }

        if (-not (Test-Path -LiteralPath $nodeDirectory)) {
            Move-Item -LiteralPath $extractedDirectory -Destination $nodeDirectory
        }
        $nodeDownloaded = $true
    } finally {
        if (Test-Path -LiteralPath $temporaryDirectory) {
            Assert-ChildPath -Parent $cachePath -Child $temporaryDirectory
            Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
        }
    }
}

if (-not (Test-Path -LiteralPath $nodeExecutable) -or -not (Test-Path -LiteralPath $npmCommand)) {
    throw 'The portable Node.js runtime is incomplete after bootstrap.'
}

$cliRoot = Join-Path $cachePath 'cli'
$cliCommand = Join-Path $cliRoot 'node_modules\.bin\multiagentor-cli.cmd'
$launcher = Join-Path $cachePath 'multiagentor-cli-portable.cmd'
$previousPath = $env:PATH

try {
    $env:PATH = "$nodeDirectory;$previousPath"
    $packageJson = Join-Path $cliRoot 'node_modules\multiagentor-cli\package.json'
    $installedCliVersion = if (Test-Path -LiteralPath $packageJson) {
        [string]((Get-Content -Raw -LiteralPath $packageJson | ConvertFrom-Json).version)
    } else { '' }
    $latestCliVersion = ''
    if ($CliPackage -eq 'multiagentor-cli@latest') {
        $latestRaw = & $npmCommand view 'multiagentor-cli@latest' version --json
        if ($LASTEXITCODE -ne 0) { throw 'Failed to resolve the latest MultiAgentor CLI version from npm.' }
        $latestCliVersion = ([string]($latestRaw | ConvertFrom-Json)).Trim()
    }
    if (-not (Test-Path -LiteralPath $cliCommand) -or
        ($latestCliVersion -and $installedCliVersion -ne $latestCliVersion)) {
        $installTarget = if ($latestCliVersion) { "multiagentor-cli@$latestCliVersion" } else { $CliPackage }
        & $npmCommand install --prefix $cliRoot --no-audit --no-fund $installTarget
        if ($LASTEXITCODE -ne 0) {
            throw "npm failed to install $installTarget (exit code $LASTEXITCODE)."
        }
    }

    if (-not (Test-Path -LiteralPath $cliCommand)) {
        throw "The npm package did not create the expected CLI command: $cliCommand"
    }

    $verifiedCliVersion = [string]((Get-Content -Raw -LiteralPath $packageJson | ConvertFrom-Json).version)
    if ($latestCliVersion -and $verifiedCliVersion -ne $latestCliVersion) {
        throw "CLI verification mismatch: installed $verifiedCliVersion, expected $latestCliVersion."
    }

    & $cliCommand --help | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "The installed MultiAgentor CLI failed its --help check (exit code $LASTEXITCODE)."
    }
} finally {
    $env:PATH = $previousPath
}

$launcherLines = @(
    '@echo off',
    'setlocal',
    "set `"PATH=$nodeDirectory;%PATH%`"",
    "call `"$cliCommand`" %*",
    'exit /b %ERRORLEVEL%'
)
Set-Content -LiteralPath $launcher -Value $launcherLines -Encoding Ascii

[ordered]@{
    invocation = $launcher
    node_path = $nodeExecutable
    npm_path = $npmCommand
    node_version = (& $nodeExecutable --version).Trim()
    platform = $platform
    cache_root = $cachePath
    node_downloaded = $nodeDownloaded
    cli_version = $verifiedCliVersion
    latest_cli_version = $latestCliVersion
    cli_updated = [bool]($installedCliVersion -and $installedCliVersion -ne $verifiedCliVersion)
} | ConvertTo-Json -Compress
