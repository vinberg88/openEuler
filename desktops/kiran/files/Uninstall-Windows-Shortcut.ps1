param(
    [Parameter(Mandatory = $true)]
    [string]$Distro
)

$ErrorActionPreference = 'Stop'

$safeDistro = $Distro -replace '[^A-Za-z0-9._-]', '_'
$installRoot = Join-Path $env:LOCALAPPDATA 'openEuler-Desktop\Kiran-X410'
$installDir = Join-Path $installRoot $safeDistro
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop 'Kiran Desktop (X410).lnk'
$installedStartScript = Join-Path $installDir 'Start-Kiran-X410.ps1'

if (Test-Path -LiteralPath $shortcutPath) {
    $wsh = New-Object -ComObject WScript.Shell
    $shortcut = $wsh.CreateShortcut($shortcutPath)
    if ($shortcut.Arguments -like "*$installedStartScript*") {
        Remove-Item -LiteralPath $shortcutPath -Force
        Write-Host "Windows shortcut removed: $shortcutPath" -ForegroundColor Green
    }
    else {
        Write-Warning "The shortcut was changed and was left untouched: $shortcutPath"
    }
}
if (Test-Path -LiteralPath $installDir) {
    $resolvedRoot = [IO.Path]::GetFullPath($installRoot).TrimEnd('\') + '\'
    $resolvedTarget = [IO.Path]::GetFullPath($installDir).TrimEnd('\') + '\'
    if (-not $resolvedTarget.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove an unexpected path: $installDir"
    }
    Remove-Item -LiteralPath $installDir -Recurse -Force
    Write-Host "Windows launcher files removed: $installDir" -ForegroundColor Green
}
