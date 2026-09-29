# Contributing a desktop

New desktops should be added without changing the behavior of already tested launchers.

## Directory structure

Create:

```text
desktops/<desktop>/
├── README.md
└── files/
```

The top-level `install.sh` remains the stable entry point and dispatches to the selected desktop. Keep desktop-specific scripts and configuration under that desktop's directory.

## Required behavior

Each supported desktop must provide:

- a non-root graphical session;
- `start`, `stop`, `restart`, `status`, `doctor` and `log` commands;
- an isolated process group or systemd user unit;
- display detection that does not accidentally reuse the wrong WSLg/X410 display;
- a Windows shortcut targeting the selected WSL distribution and Linux user;
- repeat-start protection;
- explicit autostart adjustments for services that do not make sense inside WSL;
- a visible end-to-end test and screenshot.

## Status changes

Do not mark a desktop as tested merely because its packages install. Update `DESKTOPS.md` to ✅ only after the complete checklist in that document passes.

## Validation

Before proposing a change, run:

```bash
bash -n install.sh
bash -n uninstall.sh
bash -n desktops/<desktop>/files/*
git diff --check
```

PowerShell scripts must also be parsed or executed on Windows before publication.

If a downloaded file under `desktops/kiran/files/` changes, update its embedded SHA-256 digest in `install.sh` or `uninstall.sh` in the same change.
