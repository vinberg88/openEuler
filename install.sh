#!/usr/bin/env bash
set -Eeuo pipefail

desktop="${1:-kiran}"
mode="${2:-install}"
repo_ref="${OPENEULER_DESKTOP_REF:-main}"
base_url="${OPENEULER_DESKTOP_BASE:-https://raw.githubusercontent.com/vinberg88/openEuler/${repo_ref}}"

usage() {
    cat <<'EOF'
Usage: bash install.sh [desktop] [--check]

Available desktops:
  kiran    Kiran Desktop + X410 for openEuler 25.09

Modes:
  --check  Download and validate files without installing them

Optional test/development variables:
  OPENEULER_DESKTOP_BASE=file:///absolute/repository/path
  OPENEULER_DESKTOP_REF=branch-or-tag
EOF
}

case "$desktop" in
    -h|--help) usage; exit 0 ;;
    kiran) ;;
    *) echo "Unsupported desktop: $desktop" >&2; usage >&2; exit 2 ;;
esac

case "$mode" in
    install|"") ;;
    --check) ;;
    *) echo "Unsupported mode: $mode" >&2; usage >&2; exit 2 ;;
esac

if [[ ${EUID} -eq 0 ]]; then
    echo "Run this installer as your normal Linux user, not with sudo." >&2
    echo "The installer asks for sudo only when system files are copied." >&2
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    echo "Cannot identify the Linux distribution." >&2
    exit 1
fi

. /etc/os-release
if [[ ${ID,,} != "openeuler" ]]; then
    echo "This installer currently supports openEuler only; detected: ${PRETTY_NAME:-$ID}." >&2
    exit 1
fi

if ! grep -qi microsoft /proc/sys/kernel/osrelease; then
    echo "This installer is intended for openEuler running in WSL 2." >&2
    exit 1
fi

if [[ "$(ps -p 1 -o comm= | tr -d ' ')" != "systemd" ]]; then
    echo "systemd is not PID 1. Enable it in /etc/wsl.conf and restart WSL." >&2
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required for installation." >&2
    exit 1
fi

for command_name in systemctl wslpath dnf; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required base command is missing: $command_name" >&2
        exit 1
    fi
done

if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
    echo "Either wget or curl is required for downloading launcher files." >&2
    exit 1
fi

if ! command -v powershell.exe >/dev/null 2>&1; then
    echo "Windows PowerShell interop is unavailable in this WSL distribution." >&2
    exit 1
fi

distro_name="${WSL_DISTRO_NAME:-}"
if [[ -z "$distro_name" ]]; then
    echo "WSL_DISTRO_NAME is missing. Start the installer from a normal WSL terminal." >&2
    exit 1
fi

tmp_dir="$(mktemp -d -t openeuler-desktop.XXXXXXXX)"
cleanup() {
    [[ -n ${tmp_dir:-} && -d $tmp_dir && $tmp_dir == /tmp/openeuler-desktop.* ]] && rm -rf -- "$tmp_dir"
}
trap cleanup EXIT

download() {
    local relative="$1"
    local output="$2"
    if [[ $base_url == file://* ]]; then
        cp -- "${base_url#file://}/$relative" "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --https-only -O "$output" "$base_url/$relative"
    else
        curl --fail --silent --show-error --location --proto '=https' -o "$output" "$base_url/$relative"
    fi
}

echo "Downloading Kiran/X410 launcher files ..."
for file_name in \
    kiran-x410 \
    kiran-x410-session \
    kiran-x410.service \
    Start-Kiran-X410.ps1 \
    Install-Windows-Shortcut.ps1; do
    download "desktops/kiran/files/$file_name" "$tmp_dir/$file_name"
done

bash -n "$tmp_dir/kiran-x410"
bash -n "$tmp_dir/kiran-x410-session"

if [[ $mode == "--check" ]]; then
    echo "Download and syntax validation completed successfully."
    exit 0
fi

sudo -v
if ! command -v kiran-session-manager >/dev/null 2>&1; then
    echo "Kiran Desktop is not installed. Installing the openEuler kiran-desktop package ..."
    sudo dnf install -y kiran-desktop
fi

for command_name in kiran-session-manager marco kiran-panel caja xdpyinfo flock; do
    if ! command -v "$command_name" >/dev/null 2>&1 && \
       [[ ! -x "/usr/libexec/$command_name" ]]; then
        echo "Kiran installation is incomplete; required command is missing: $command_name" >&2
        exit 1
    fi
done

echo "Installing Linux launcher and user service ..."
sudo install -D -o root -g root -m 0755 "$tmp_dir/kiran-x410" /usr/local/bin/kiran-x410
sudo install -D -o root -g root -m 0755 "$tmp_dir/kiran-x410-session" /usr/local/libexec/kiran-x410-session
sudo install -D -o root -g root -m 0644 "$tmp_dir/kiran-x410.service" /etc/systemd/user/kiran-x410.service
systemctl --user daemon-reload

windows_helper="$(wslpath -w "$tmp_dir/Install-Windows-Shortcut.ps1")"
windows_start_source="$(wslpath -w "$tmp_dir/Start-Kiran-X410.ps1")"

echo "Creating the Windows desktop shortcut ..."
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$windows_helper" \
    -Distro "$distro_name" \
    -LinuxUser "$(id -un)" \
    -StartScriptSource "$windows_start_source"

echo
echo "Running diagnostics ..."
/usr/local/bin/kiran-x410 doctor

cat <<'EOF'

Installation complete.

Use the "Kiran Desktop (X410)" shortcut on the Windows desktop.
Commands: kiran-x410 start|stop|restart|status|doctor|log
EOF
