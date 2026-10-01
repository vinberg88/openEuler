# WSL - openEuler Desktop Collection.

![openEuler](https://img.shields.io/badge/openEuler-WSL-0A7B83?style=for-the-badge&logo=linux&logoColor=white)
![Windows 11](https://img.shields.io/badge/Windows_11-WSL_2-0078D4?style=for-the-badge&logo=windows11&logoColor=white)
![Kiran](https://img.shields.io/badge/Kiran-X410_tested-2EA3F2?style=for-the-badge)
![Release](https://img.shields.io/github/v/release/vinberg88/openEuler?style=for-the-badge&label=Release)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

A community collection for running complete openEuler desktop environments in WSL 2 on Windows.

The first tested desktop is **Kiran Desktop on openEuler 25.09 through X410**. The repository is structured so UKUI, GNOME, KDE Plasma, XFCE, Deepin and other desktops can be added without mixing their launchers, settings or diagnostics.

> This is a personal/community project. It is not an official openEuler, KylinSec, Microsoft or X410 project.

---

# Next project - KDE 6 and openEuler - WSL - 2026

Working on that right now.. Comming project for openEuler  25.09 

About OpenEuler 25.09 - https://www.openeuler.org/en

OpenEuler is an open source project incubated and operated
by the OpenAtom Foundation. EulerOS is a commercial Linux
distribution developed by Huawei based on Red Hat
Enterprise Linux. To provide an operating system for
server and cloud environments. Its open-source Community
version is known as openEuler, of which source code was
released by Huawei at Gitee on December 31, 2019. OpenEuler
became an open-source project operated by OpenAtom
Foundation after Huawei donated the source code of
openEuler to the foundation on November.  

<p align="center">
<a href="https://github.com/vinberg88">
<img width="1920" height="1080" alt="openEuler 25.09 KDE" src="https://github.com/user-attachments/assets/20384504-3175-48a2-8131-63b4e8e0e640" />
</p>

What is KDE - Desktop - https://kde.org

Use Plasma to surf the web; keep in touch with colleagues, 
friends and family; manage your files, enjoy music and
videos; and get creative and productive at work. Do it all
in a beautiful Environment that adapts to your needs,
and with the safety, privacy-protection and peace of mind
that the best Free Open Source Software has to offer. KDE
Plasma is a Desktop for next life =)

---

# WSL - OpenEuler via GNOME Desktop - 2026

How to install GNOME deskop on openEuler 25.09

<p align="center">
<a href="https://github.com/vinberg88/openEuler/blob/main/OpenEuler25.09-GNOME.txt">
<img width="1920" height="1080" alt="openEuler-Gnome-25 09" src="https://github.com/user-attachments/assets/b0ee6091-f0b8-46d1-a25a-12879e8e9f90" />
</p>

- [Install GNOME desktop via openEuler](OpenEuler25.09-GNOME.txt)
- **YouTube video guide:** [How to install GNOME via openEuler](https://www.youtube.com/watch?v=2XqTazXq5JY)

About Gnome desktop - https://www.gnome.org

Every part of GNOME has been designed to make it simple
and easy to use. The Activities Overview is a simple
way to access all your basic tasks. A press of a button
is all it takes to view your open windows, launch
applications, or check if you have new messages. Having
everything in one convenient place means you don’t have
to learn your way around a maze of different technologies. 
GNOME provides a focused working environment that helps
you get things done.

---

# WSL - openEuler via Kiran Desktop - 2026

![Kiran Desktop running on openEuler 25.09 in X410](images/OpenEuler25.09-KIRAN.png)

## Installation walkthrough and video

- [Complete Kiran installation walkthrough](OpenEuler25.09-KIRAN.txt)
- **YouTube video guide:** [How to install KIRAN via openEuler](https://www.youtube.com/watch?v=2XqTazXq5JY)

The supported quick installer below is the shortest route. The longer walkthrough also covers the openEuler setup, optional desktop applications and the final X410 startup steps.

## Quick install: Kiran + X410

Run this inside the openEuler WSL distribution as your normal Linux user, not as root:

```bash
wget https://raw.githubusercontent.com/vinberg88/openEuler/main/install.sh
less install.sh
bash install.sh kiran
```

The installer downloads the Kiran launcher files, installs the complete openEuler `kiran-desktop` package when needed, validates the environment, installs the Linux service and creates a **Kiran Desktop (X410)** shortcut on the Windows desktop.

Every downloaded launcher file is checked against a SHA-256 digest embedded in the reviewed installer before it can be executed or installed.

Keep download and execution as separate steps. Do not pipe a remote installer directly into a shell; downloading it first makes the exact code being granted installation privileges visible and reviewable.

## Requirements

- Windows 11 with WSL 2
- openEuler 25.09
- systemd enabled in `/etc/wsl.conf`
- openEuler repositories providing the `kiran-desktop` package
- X410 installed on Windows and available through its app execution alias
- `sudo`, `wget` or `curl`

## Commands after installation

```bash
kiran-x410 start
kiran-x410 stop
kiran-x410 restart
kiran-x410 status
kiran-x410 doctor
kiran-x410 log
```

## Normal start

1. Double-click **Kiran Desktop (X410)** on the Windows desktop.
2. Wait a few seconds while the shortcut starts X410 in Desktop mode and launches the managed Kiran session.
3. Leave X410 running quietly in the Windows background or system tray for the entire Kiran session.

X410 is the display server behind the desktop. It should not need a separate visible control window, but it must remain running while Kiran is in use. Do not start `kiran-session-manager` manually alongside the shortcut, because that can create duplicate panels and unpredictable sessions.

## Uninstall the integration

Download and inspect the uninstaller, then run it as the same normal Linux user:

```bash
wget https://raw.githubusercontent.com/vinberg88/openEuler/main/uninstall.sh
less uninstall.sh
bash uninstall.sh kiran
```

This removes the launcher, user service and Windows shortcut. It deliberately keeps the openEuler `kiran-desktop` packages, personal files and session logs.

## Desktop collection

| Desktop | openEuler version | Display path | Status |
|---|---:|---|---|
| Kiran Desktop | 25.09 | X410 / X11 | ✅ Tested |
| UKUI | To be selected | X410 / X11 | 🧪 Planned |
| GNOME | 25.09 | WSLg or X410 | ✅ Tested |
| KDE Plasma | To be selected | X410 / X11 | 🧪 Planned |
| XFCE | To be selected | X410 / X11 | 🧪 Planned |
| Deepin Desktop | To be selected | X410 / X11 | 🧪 Planned |
| Cinnamon | To be selected | X410 / X11 | 🧪 Planned |
| MATE | To be selected | X410 / X11 | 🧪 Planned |
| LXQt | To be selected | X410 / X11 | 🧪 Planned |

See [DESKTOPS.md](DESKTOPS.md) for the test standard and roadmap.

## What the Kiran installer fixes

- always runs Kiran as the selected non-root Linux user;
- discovers the Windows host address instead of reusing WSLg's `DISPLAY`;
- starts one controlled X11 session with Marco, Kiran Panel and Caja;
- keeps WSL alive through a hidden Windows-side holder process;
- preserves WSLg audio when its Pulse server is available;
- prevents duplicate session launches with a runtime lock;
- disables WSL-inappropriate network, printer, SELinux and lock-screen applets for the current user;
- writes a readable session log under `~/.local/state/kiran-x410/`.

## Repository layout

```text
.
├── LICENSE
├── OpenEuler25.09-KIRAN.txt
├── install.sh
├── uninstall.sh
├── DESKTOPS.md
├── desktops/
│   └── kiran/
│       ├── README.md
│       └── files/
└── images/
```

Each future desktop receives its own installer assets and documentation under `desktops/<name>/`.

## Troubleshooting

### `powershell.exe: Permission denied`

If the installer reaches the Windows shortcut step and reports that `powershell.exe` is not permitted, check `/etc/wsl.conf`. An automount option such as `fmask=11` removes the execute bit from Windows programs for normal Linux users. Change that option to:

```ini
[automount]
enabled=true
root=/mnt/
options="metadata,umask=22,fmask=022"
```

Then close WSL and run this from **Windows PowerShell**:

```powershell
wsl --shutdown
```

Start openEuler again and rerun `bash install.sh kiran`. The installer is repeatable, so the partially completed first run does not need to be removed.

Run:

```bash
kiran-x410 doctor
kiran-x410 log 200
```

Do not start `kiran-session-manager`, `kiran-panel` or the desktop with `sudo`. Mixing root sessions, WSLg's display and X410 is the main cause of duplicated panels and unpredictable startup.

<p align="center">
<a href="https://github.com/vinberg88">
<img width="500" height="150" alt="openEuler" src="https://github.com/user-attachments/assets/b334c603-0688-4dfd-8cc2-ddad33dce160" />
</p>

## License

The launcher, installer and repository documentation are available under the [MIT License](LICENSE). Third-party projects and packages retain their own licenses.
