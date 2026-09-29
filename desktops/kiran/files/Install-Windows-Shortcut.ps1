param(
    [Parameter(Mandatory = $true)]
    [string]$Distro,

    [Parameter(Mandatory = $true)]
    [string]$LinuxUser,

    [Parameter(Mandatory = $true)]
    [string]$StartScriptSource
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $StartScriptSource)) {
    throw "Start script not found: $StartScriptSource"
}

$x410 = (Get-Command 'x410.exe' -ErrorAction Stop).Source
$safeDistro = $Distro -replace '[^A-Za-z0-9._-]', '_'
$installDir = Join-Path $env:LOCALAPPDATA "openEuler-Desktop\Kiran-X410\$safeDistro"
New-Item -ItemType Directory -Path $installDir -Force | Out-Null

$installedStartScript = Join-Path $installDir 'Start-Kiran-X410.ps1'
Copy-Item -LiteralPath $StartScriptSource -Destination $installedStartScript -Force

$config = [ordered]@{
    Distro = $Distro
    LinuxUser = $LinuxUser
} | ConvertTo-Json
[IO.File]::WriteAllText(
    (Join-Path $installDir 'config.json'),
    $config,
    [Text.UTF8Encoding]::new($false)
)

$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop 'Kiran Desktop (X410).lnk'
if (Test-Path -LiteralPath $shortcutPath) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    Copy-Item -LiteralPath $shortcutPath -Destination "$shortcutPath.$stamp.bak"
}

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath = Join-Path $PSHOME 'powershell.exe'
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$installedStartScript`""
$shortcut.WorkingDirectory = $installDir
$shortcut.IconLocation = "$x410,0"
$shortcut.Description = "Start Kiran Desktop in X410 ($Distro)"
$shortcut.Save()

Write-Host "Windows shortcut created: $shortcutPath" -ForegroundColor Green
