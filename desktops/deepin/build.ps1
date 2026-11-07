[CmdletBinding()]
param(
    [ValidateSet('26.09')]
    [string]$Version = '26.09',

    [switch]$ForceDownload
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$workRoot = Join-Path $projectRoot 'work'
$downloadRoot = Join-Path $workRoot 'downloads'
$outputRoot = Join-Path $projectRoot 'dist'
$configureScript = Join-Path $projectRoot 'scripts\configure-wsl.sh'
$filesRoot = Join-Path $projectRoot 'files'

$releases = [ordered]@{
    '26.09' = @{
        ReleasePath = '26.09'
        FileLabel = '26.09'
        DefaultName = 'openEuler-26.09-Deepin'
        Sha256 = '875c691f749c2a7d6f08b0b90285196212bd8fe0694a7f0f401249945ee7d0ea'
    }
}
function Assert-LastExitCode {
    param([string]$Operation)
    if ($LASTEXITCODE -ne 0) {
        throw "$Operation failed with exit code $LASTEXITCODE."
    }
}

function Invoke-Wsl {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$Operation
    )
    & wsl.exe @Arguments
    Assert-LastExitCode $Operation
}

foreach ($command in 'wsl.exe', 'curl.exe', 'tar.exe') {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Required command '$command' was not found."
    }
}
if (-not (Test-Path -LiteralPath $configureScript)) {
    throw "Missing configuration script: $configureScript"
}

New-Item -ItemType Directory -Force -Path $workRoot, $downloadRoot, $outputRoot | Out-Null
$selected = @($Version)

foreach ($releaseKey in $selected) {
    $release = $releases[$releaseKey]
    $archiveName = "openEuler-$($release.FileLabel).tar.xz"
    $archivePath = Join-Path $downloadRoot $archiveName
    $url = "https://repo.openeuler.org/openEuler-$($release.ReleasePath)/docker_img/x86_64/openEuler-docker.x86_64.tar.xz"
    $buildRoot = Join-Path $workRoot "build-$($release.FileLabel)"
    $installRoot = Join-Path $workRoot "wsl-$($release.FileLabel)"
    $tempDistro = "openEuler-build-$($releaseKey)-$PID"
    $outputPath = Join-Path $outputRoot "openEuler-$($release.FileLabel)-Deepin-x86_64.wsl"

    Write-Host "`n=== openEuler $releaseKey ===" -ForegroundColor Cyan

    $downloadNeeded = $ForceDownload -or -not (Test-Path -LiteralPath $archivePath)
    if (-not $downloadNeeded) {
        $existingHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
        $downloadNeeded = $existingHash -ne $release.Sha256
    }
    if ($downloadNeeded) {
        Write-Host 'Downloading official openEuler image...'
        & curl.exe --fail --location --retry 4 --retry-all-errors --output "$archivePath.partial" $url
        Assert-LastExitCode "Download of openEuler $releaseKey"
        Move-Item -Force -LiteralPath "$archivePath.partial" -Destination $archivePath
    }

    $actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $release.Sha256) {
        throw "Checksum mismatch for $archiveName. Expected $($release.Sha256), got $actualHash."
    }
    Write-Host 'SHA-256 verified.'

    if (Test-Path -LiteralPath $buildRoot) {
        Remove-Item -Recurse -Force -LiteralPath $buildRoot
    }
    if (Test-Path -LiteralPath $installRoot) {
        Remove-Item -Recurse -Force -LiteralPath $installRoot
    }
    New-Item -ItemType Directory -Force -Path $buildRoot, $installRoot | Out-Null

    $manifestText = (& tar.exe -xOf $archivePath manifest.json) -join "`n"
    Assert-LastExitCode 'Reading the container manifest'
    $manifest = $manifestText | ConvertFrom-Json
    $layers = @($manifest[0].Layers)
    if ($layers.Count -ne 1) {
        throw "The upstream image layout changed: expected one rootfs layer, found $($layers.Count)."
    }
    $layerRelativePath = [string]$layers[0]
    & tar.exe -xf $archivePath -C $buildRoot $layerRelativePath
    Assert-LastExitCode 'Extracting the root filesystem layer'
    $layerPath = Join-Path $buildRoot ($layerRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)

    try {
        Write-Host 'Creating temporary WSL build environment...'
        Invoke-Wsl -Arguments @('--import', $tempDistro, $installRoot, $layerPath, '--version', '2') -Operation 'WSL import'

        Write-Host 'Installing WSL essentials and configuration...'
        $configureContent = (Get-Content -Raw -LiteralPath $configureScript).Replace("`r`n", "`n")
        $configureContent |
            & wsl.exe -d $tempDistro -u root -- /bin/bash -s -- $releaseKey $release.DefaultName $release.ReleasePath
        Assert-LastExitCode "Configuration of openEuler $releaseKey"

        Write-Host 'Installing Deepin and X11 tools from openEuler repositories...'
        Invoke-Wsl -Arguments @('-d', $tempDistro, '-u', 'root', '--', 'dnf', '-y', 'install', 'dde', 'xdpyinfo', 'git') -Operation 'Deepin installation'

        $launcherFiles = @(
            @{ Name = 'deepin-x410'; Target = '/usr/local/bin/deepin-x410'; Mode = '0755' },
            @{ Name = 'deepin-x410-session'; Target = '/usr/local/libexec/deepin-x410-session'; Mode = '0755' },
            @{ Name = 'deepin-x410.service'; Target = '/etc/systemd/user/deepin-x410.service'; Mode = '0644' }
        )
        foreach ($item in $launcherFiles) {
            $source = Join-Path $filesRoot $item.Name
            if (-not (Test-Path -LiteralPath $source)) { throw "Missing launcher file: $source" }
            $linuxSource = (& wsl.exe -d $tempDistro -u root -- wslpath -u $source).Trim()
            Assert-LastExitCode "Mapping $source"
            Invoke-Wsl -Arguments @('-d', $tempDistro, '-u', 'root', '--', 'install', '-D', '-o', 'root', '-g', 'root', '-m', $item.Mode, $linuxSource, $item.Target) -Operation "Installing $($item.Name)"
        }

        Invoke-Wsl -Arguments @('-d', $tempDistro, '-u', 'root', '--', 'bash', '-lc', 'bash -n /usr/local/bin/deepin-x410 /usr/local/libexec/deepin-x410-session && command -v kwin_x11 && command -v startdde && command -v xdpyinfo') -Operation 'Launcher validation'
        Invoke-Wsl -Arguments @('-d', $tempDistro, '-u', 'root', '--', 'bash', '-lc', 'dnf clean all >/dev/null && rm -rf /var/cache/dnf/* /var/log/dnf* /var/log/hawkey.log /var/log/journal/* && : > /etc/machine-id && rm -f /var/lib/dbus/machine-id /etc/resolv.conf') -Operation 'Cleaning build state'

        Invoke-Wsl -Arguments @('--terminate', $tempDistro) -Operation 'Stopping the temporary distribution'
        if (Test-Path -LiteralPath $outputPath) {
            Remove-Item -Force -LiteralPath $outputPath
        }

        Write-Host "Exporting $([IO.Path]::GetFileName($outputPath))..."
        Invoke-Wsl -Arguments @('--export', $tempDistro, $outputPath, '--format', 'tar.xz') -Operation 'WSL export'
    }
    finally {
        & wsl.exe --unregister $tempDistro 2>$null | Out-Null
    }

    $packageHash = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $checksumPath = "$outputPath.sha256"
    "$packageHash  $([IO.Path]::GetFileName($outputPath))`n" |
        Set-Content -NoNewline -Encoding ascii -LiteralPath $checksumPath
    $sizeMiB = [math]::Round((Get-Item -LiteralPath $outputPath).Length / 1MB, 1)
    Write-Host "Ready: $outputPath ($sizeMiB MiB)" -ForegroundColor Green
}

Write-Host "`nBuild complete. Packages are in: $outputRoot" -ForegroundColor Green
