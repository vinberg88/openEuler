#!/usr/bin/env bash
set -Eeuo pipefail

desktop="${1:-kiran}"
repo_ref="${OPENEULER_DESKTOP_REF:-main}"
base_url="${OPENEULER_DESKTOP_BASE:-https://raw.githubusercontent.com/vinberg88/openEuler/${repo_ref}}"

usage() {
    cat <<'EOF'
Usage: bash uninstall.sh [desktop]

Available desktops:
  kiran    Remove the Kiran/X410 integration

The openEuler kiran-desktop package and personal files are kept.
EOF
}

case "$desktop" in
    -h|--help) usage; exit 0 ;;
    kiran) ;;
    *) echo "Unsupported desktop: $desktop" >&2; usage >&2; exit 2 ;;
esac

if [[ ${EUID} -eq 0 ]]; then
    echo "Run this uninstaller as the Linux user who installed Kiran/X410, not with sudo." >&2
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    echo "Cannot identify the Linux distribution." >&2
    exit 1
fi

. /etc/os-release
if [[ ${ID,,} != "openeuler" ]] || ! grep -qi microsoft /proc/sys/kernel/osrelease; then
    echo "This uninstaller is intended for openEuler running in WSL 2." >&2
    exit 1
fi

for command_name in sudo systemctl powershell.exe sha256sum wslpath; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command is missing: $command_name" >&2
        exit 1
    fi
done

powershell_path="$(command -v powershell.exe 2>/dev/null || true)"
if [[ ! -x "$powershell_path" ]]; then
    echo "Windows PowerShell was found but is not executable by $(id -un): $powershell_path" >&2
    echo "Check /etc/wsl.conf: use automount fmask=022, then restart WSL." >&2
    exit 1
fi

distro_name="${WSL_DISTRO_NAME:-}"
if [[ -z "$distro_name" ]]; then
    echo "WSL_DISTRO_NAME is missing. Start the uninstaller from a normal WSL terminal." >&2
    exit 1
fi

tmp_dir="$(mktemp -d -t openeuler-desktop-uninstall.XXXXXXXX)"
cleanup() {
    [[ -n ${tmp_dir:-} && -d $tmp_dir && $tmp_dir == /tmp/openeuler-desktop-uninstall.* ]] && rm -rf -- "$tmp_dir"
}
trap cleanup EXIT

helper_name="Uninstall-Windows-Shortcut.ps1"
helper_path="$tmp_dir/$helper_name"
helper_sha256="dfbf58e412eca6aed7a3df8c0f10b19103d5726009717ffb7d0b6df8dd5b37c0"
helper_url="$base_url/desktops/kiran/files/$helper_name"

if [[ $base_url == file://* ]]; then
    cp -- "${base_url#file://}/desktops/kiran/files/$helper_name" "$helper_path"
elif command -v wget >/dev/null 2>&1; then
    wget -q --https-only -O "$helper_path" "$helper_url"
elif command -v curl >/dev/null 2>&1; then
    curl --fail --silent --show-error --location --proto '=https' -o "$helper_path" "$helper_url"
else
    echo "Either wget or curl is required to retrieve the Windows cleanup helper." >&2
    exit 1
fi

actual_sha256="$(sha256sum "$helper_path" | awk '{print $1}')"
if [[ $actual_sha256 != "$helper_sha256" ]]; then
    echo "Checksum verification failed for $helper_name; nothing was removed." >&2
    exit 1
fi

echo "Stopping the Kiran/X410 session ..."
systemctl --user stop kiran-x410.service >/dev/null 2>&1 || true

echo "Removing the Kiran/X410 integration ..."
sudo rm -f -- \
    /usr/local/bin/kiran-x410 \
    /usr/local/libexec/kiran-x410-session \
    /etc/systemd/user/kiran-x410.service
systemctl --user daemon-reload
systemctl --user reset-failed >/dev/null 2>&1 || true

windows_helper="$(wslpath -w "$helper_path")"
"$powershell_path" -NoProfile -ExecutionPolicy Bypass -File "$windows_helper" -Distro "$distro_name"

autostart_dir="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
for desktop_file in \
    kiran-network-status-icon.desktop \
    kiran-screensaver.desktop \
    print-applet.desktop \
    sealertauto.desktop; do
    candidate="$autostart_dir/$desktop_file"
    if [[ -f $candidate ]] && [[ "$(<"$candidate")" == $'[Desktop Entry]\nType=Application\nHidden=true' ]]; then
        rm -f -- "$candidate"
    fi
done

rm -f -- "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/kiran-x410.env"

cat <<'EOF'

Kiran/X410 integration removed.
The openEuler Kiran packages, your home files and session logs were kept.
EOF
