#!/usr/bin/env bash
set -Eeuo pipefail

desktop="${1:-kiran}"
mode="${2:-install}"
repo_ref="${OPENEULER_DESKTOP_REF:-main}"
base_url="${OPENEULER_DESKTOP_BASE:-https://raw.githubusercontent.com/vinberg88/openEuler/${repo_ref}}"

usage() {
    cat <<'EOF'
Usage: bash install.sh [desktop] [--check]
       bash install.sh list

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
    list) usage; exit 0 ;;
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

for command_name in systemctl wslpath dnf sha256sum; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required base command is missing: $command_name" >&2
        exit 1
    fi
done

if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
    echo "Either wget or curl is required for downloading launcher files." >&2
    exit 1
fi

if [[ $mode != "--check" ]]; then
    powershell_path="$(command -v powershell.exe 2>/dev/null || true)"
    if [[ -z "$powershell_path" ]]; then
        echo "Windows PowerShell interop is unavailable in this WSL distribution." >&2
        exit 1
    fi

    if [[ ! -x "$powershell_path" ]]; then
        echo "Windows PowerShell was found but is not executable by $(id -un): $powershell_path" >&2
        echo "Check /etc/wsl.conf: an automount fmask such as fmask=11 removes the execute bit." >&2
        echo "Use fmask=022, then run 'wsl --shutdown' from Windows PowerShell and try again." >&2
        exit 1
    fi
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
declare -A expected_sha256=(
    [kiran-x410]="0bf4f71879025eb840ec5c980829ae8e38107239a79173ce56e210f5abd1a8a0"
    [kiran-x410-session]="0467a6cbe711076ed29c5964adc7159d480efe45075477acd07de0546868aedb"
    [kiran-x410.service]="9581ded2f4addbd3a0bf6b53bd8d254738f8a428a79d8905d98d49ca6be0c6ce"
    [Start-Kiran-X410.ps1]="8654f0735b76779b6441ea15fb1cd1ddf8001b0ea278ab9c2594654bac3df583"
    [Install-Windows-Shortcut.ps1]="d08e98e1978cd81678b36846498e114ecd5e85bbc26eb25f9e06724f758f26b3"
)
for file_name in \
    kiran-x410 \
    kiran-x410-session \
    kiran-x410.service \
    Start-Kiran-X410.ps1 \
    Install-Windows-Shortcut.ps1; do
    download "desktops/kiran/files/$file_name" "$tmp_dir/$file_name"
    # Git stores the text assets with LF while a Windows checkout may expose
    # PowerShell files with CRLF. Verify identical text independent of EOL style.
    actual_sha256="$(sed 's/\r$//' "$tmp_dir/$file_name" | sha256sum | awk '{print $1}')"
    if [[ $actual_sha256 != "${expected_sha256[$file_name]}" ]]; then
        echo "Checksum verification failed for $file_name; nothing was installed." >&2
        exit 1
    fi
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
"$powershell_path" -NoProfile -ExecutionPolicy Bypass -File "$windows_helper" \
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
