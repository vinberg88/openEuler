$ErrorActionPreference = 'Stop'

$configPath = Join-Path $PSScriptRoot 'config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Konfiguration saknas: $configPath. Kor Install-Kiran-X410.ps1 igen."
}
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$distro = [string]$config.Distro
$linuxUser = [string]$config.LinuxUser
if ([string]::IsNullOrWhiteSpace($distro) -or [string]::IsNullOrWhiteSpace($linuxUser)) {
    throw 'config.json maste innehalla Distro och LinuxUser.'
}
$x410 = (Get-Command 'x410.exe' -ErrorAction Stop).Source

if (-not (Get-Process -Name 'X410' -ErrorAction SilentlyContinue)) {
    Write-Host 'Startar X410 i Desktop-lage ...' -ForegroundColor Cyan
    Start-Process -FilePath $x410 -ArgumentList '/desktop' -WindowStyle Hidden
    Start-Sleep -Seconds 3
}

Write-Host 'Startar Kiran Desktop ...' -ForegroundColor Cyan
$wslArguments = @(
    '-d', $distro,
    '-u', $linuxUser,
    '--', '/usr/local/bin/kiran-x410', 'run'
)
Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\wsl.exe') -ArgumentList $wslArguments -WindowStyle Hidden | Out-Null

$started = $false
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    Start-Sleep -Milliseconds 500
    & wsl.exe -d $distro -u $linuxUser -- systemctl --user is-active --quiet kiran-x410.service
    if ($LASTEXITCODE -eq 0) {
        $started = $true
        break
    }
}

if (-not $started) {
    Write-Host ''
    Write-Host 'Kiran kunde inte startas. Kor diagnostiken med:' -ForegroundColor Red
    Write-Host "  wsl -d $distro -u $linuxUser -- kiran-x410 doctor"
    Write-Host "  wsl -d $distro -u $linuxUser -- kiran-x410 log"
    Read-Host 'Tryck Enter for att stanga'
    exit 1
}

Write-Host 'Klart - Kiran kor i X410.' -ForegroundColor Green
