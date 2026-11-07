#!/usr/bin/env bash
set -Eeuo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
files="$here/files"

if [[ ${EUID} -eq 0 ]]; then
    echo 'Run as your normal WSL user, without sudo.' >&2
    exit 1
fi
. /etc/os-release
if [[ ${ID,,} != openeuler || ${VERSION_ID:-} != 26.09 ]]; then
    echo 'This installer supports openEuler 26.09 only.' >&2
    exit 1
fi
if ! grep -qi microsoft /proc/sys/kernel/osrelease; then
    echo 'This installer supports WSL 2 only.' >&2
    exit 1
fi
if [[ $(ps -p 1 -o comm= | tr -d ' ') != systemd ]]; then
    echo 'Enable systemd in /etc/wsl.conf and restart WSL first.' >&2
    exit 1
fi
for cmd in sudo dnf systemctl wslpath powershell.exe; do
    command -v "$cmd" >/dev/null || { echo "Missing command: $cmd" >&2; exit 1; }
done
if [[ ! -x $(command -v powershell.exe) ]]; then
    echo 'Windows interop is not executable. Check /etc/wsl.conf automount fmask.' >&2
    exit 1
fi
if [[ -z ${WSL_DISTRO_NAME:-} ]]; then
    echo 'Start this from a normal WSL terminal so WSL_DISTRO_NAME is available.' >&2
    exit 1
fi
for file in deepin-x410 deepin-x410-session deepin-x410.service Start-Deepin-X410.ps1 Install-Windows-Shortcut.ps1; do
    [[ -s $files/$file ]] || { echo "Missing $files/$file" >&2; exit 1; }
done
bash -n "$files/deepin-x410" "$files/deepin-x410-session"

if ! command -v startdde >/dev/null 2>&1 ||
   ! command -v kwin_x11 >/dev/null 2>&1 ||
   ! command -v xdpyinfo >/dev/null 2>&1; then
    echo 'Installing Deepin and X11 tools from openEuler repositories ...'
    sudo -v
    sudo dnf install -y dde xdpyinfo
else
    echo 'Deepin and X11 tools are already installed.'
fi

for cmd in startdde kwin_x11 xdpyinfo; do
    command -v "$cmd" >/dev/null || { echo "Deepin installation lacks $cmd" >&2; exit 1; }
done

sudo install -D -o root -g root -m 0755 "$files/deepin-x410" /usr/local/bin/deepin-x410
sudo install -D -o root -g root -m 0755 "$files/deepin-x410-session" /usr/local/libexec/deepin-x410-session
sudo install -D -o root -g root -m 0644 "$files/deepin-x410.service" /etc/systemd/user/deepin-x410.service
systemctl --user daemon-reload

helper="$(wslpath -w "$files/Install-Windows-Shortcut.ps1")"
start_script="$(wslpath -w "$files/Start-Deepin-X410.ps1")"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$helper" \
    -Distro "$WSL_DISTRO_NAME" -LinuxUser "$(id -un)" -StartScriptSource "$start_script"

echo 'Installed. Start Deepin using the "Deepin Desktop (X410)" shortcut on the Windows desktop.'
echo 'Diagnostics: deepin-x410 doctor | deepin-x410 status | deepin-x410 log'
