# Deepin Desktop on openEuler 26.09 in WSL 2

This setup runs a complete Deepin desktop in X410 Desktop mode on Windows 11.
It includes Deepin's X11 window manager (`kwin_x11`), so application windows have
title bars and can be moved and resized. It uses native WSL systemd and does not
install a separate systemd namespace workaround.

## Requirements

- Windows 11 with WSL 2 and an x86-64 openEuler 26.09 distribution.
- [X410](https://x410.dev/) installed on Windows. X410 is a separate product.
- An ordinary Linux user with `sudo` access and WSL systemd enabled.
- The openEuler OS, everything, EPOL, and update repositories.

The official openEuler DDE package is installed with `dnf install dde`. WSL does
not use a graphical login manager, so this project supplies a launcher that
connects DDE to X410 and starts KWin explicitly. Do not set `graphical.target`
as the default WSL target.

## Install in an existing openEuler 26.09 WSL distribution

In an openEuler terminal, clone and inspect the repository, then run:

```bash
sudo dnf install -y git
git clone https://github.com/vinberg88/openEuler.git
cd openEuler
bash desktops/deepin/install.sh
```

The installer installs DDE and the X11 display test utility from signed
openEuler repositories, adds a user service, and creates a **Deepin Desktop
(X410)** shortcut on the Windows desktop. The shortcut starts X410 in Desktop
mode when necessary and then launches DDE in the selected WSL distribution.

## Ready-made WSL package

The [release candidate](https://github.com/vinberg88/openEuler/releases/tag/deepin-26.09-rc1)
contains `openEuler-26.09-Deepin-x86_64.wsl`, a clean openEuler 26.09 base
plus DDE and the launcher. Import it with `wsl --install --from-file`.
Create a Linux user at first launch,
then run `bash desktops/deepin/install.sh` from this repository to add your
Windows shortcut. The package contains no personal account or user files.
For an offline first start, launch X410 in Desktop mode on Windows and run
`deepin-x410 run` in the openEuler terminal. Keep the terminal open while
using Deepin; press Ctrl+C to stop the desktop.

To reproduce the package on Windows, run `desktops/deepin/build.ps1` in
PowerShell. It verifies the official openEuler 26.09 container image against a
pinned SHA-256 digest, imports it into a temporary WSL distribution, installs
DDE and the launcher, clears runtime state, then exports the `.wsl` file and
its checksum under `desktops/deepin/dist/`.
The archive uses WSL's `tar.xz` export format to keep the download smaller.

## Diagnostics

```bash
deepin-x410 doctor
deepin-x410 status
deepin-x410 log
```

If the shortcut cannot connect to X410, check that X410 runs in Desktop mode
and that the Windows firewall permits its private-network connection. The
launcher asks Windows for the WSL adapter IP and tests it before the Linux
route, DNS and localhost candidates. The DNS server address can differ from
the Windows X410 address. If
windows open without borders, check `deepin-x410 log` for KWin errors.
If package downloads fail, check `ip -4 -br addr` and `ip -4 route`. Interface
names vary by WSL networking mode. If there is no IPv4 address or default
route, restart WSL from Windows with `wsl --shutdown`. If that does not help,
try `networkingMode=consomme` under `[wsl2]` in the Windows `.wslconfig` file
(`notepad $env:USERPROFILE\.wslconfig` in PowerShell), then shut down WSL
again. This changes networking for every WSL 2 distro, so
remove the line and restart WSL if it affects another distro. We verified
`dnf makecache --refresh` against all four repositories with this mode on a
WSL 3.0.4 host where NAT and mirrored mode did not provide IPv4. DNS changes
alone cannot restore a missing IPv4 address.

To stop DDE without closing X410, run `deepin-x410 stop`.

openEuler 26.09 is an innovation release with a planned support end in March
2027. This is a community WSL integration, not an official openEuler or Deepin
image.
