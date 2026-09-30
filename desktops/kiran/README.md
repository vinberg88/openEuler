# Kiran Desktop on openEuler WSL

## Tested combination

- openEuler 25.09
- WSL 2 with systemd
- Kiran Desktop 2.6 family packages
- X410 5.x in Desktop mode
- Windows 11
- X11 session using Marco, Kiran Panel and Caja
- WSLg Pulse audio path when available

## Install

From the repository root:

```bash
bash install.sh kiran
```

If the `kiran-desktop` metapackage is missing, the installer installs it from the configured openEuler repositories before setting up X410 integration.

Or download the published installer:

```bash
wget https://raw.githubusercontent.com/vinberg88/openEuler/main/install.sh
less install.sh
bash install.sh kiran
```

The installer verifies the SHA-256 digest of every downloaded launcher file before using it.

## Normal start

Start **Kiran Desktop (X410)** from the Windows desktop shortcut and wait a few seconds. The shortcut starts X410 in Desktop mode, launches the managed Kiran session and keeps WSL alive.

Leave X410 running quietly in the Windows background or system tray for the entire session. X410 is the display server, so closing it also closes Kiran's graphical display. Do not run `kiran-session-manager` separately while the shortcut-managed session is active.

## Uninstall the integration

From the repository root:

```bash
bash uninstall.sh kiran
```

This keeps the Kiran packages, personal files and session logs.

## Why a managed launcher is needed

Starting `kiran-session-manager`, `kiran-panel` or individual components manually can mix:

- the root and normal-user sessions;
- WSLg's built-in display and X410's display;
- multiple panels and file-manager desktop windows;
- independent D-Bus and systemd user lifetimes.

The managed launcher selects one display, one user and one systemd unit. A hidden Windows-side `wsl.exe` holder prevents WSL from shutting down while the graphical desktop is still being used.

## WSL-specific autostart adjustments

The launcher creates per-user overrides that disable:

- Kiran's NetworkManager status icon, because Windows owns the WSL network;
- the Kiran screen locker, which can leave an inaccessible lock prompt in X410;
- the printer applet when its CUPS integration is unavailable;
- the SELinux troubleshooter applet because SELinux is not active in this WSL setup.

These adjustments do not disable the Kiran panel, audio, desktop icons, applications or settings daemon.

## Diagnostics

```bash
kiran-x410 doctor
kiran-x410 status
kiran-x410 log 200
```
