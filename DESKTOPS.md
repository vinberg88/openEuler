# Desktop roadmap

This repository reports only what has been visibly tested. Package installation or a process staying alive is not enough to mark a desktop as working.

## Status legend

- ✅ **Tested** — installation, start, stop, restart, visible desktop, panel/window manager, Windows shortcut, audio path and repeat startup have been checked.
- 🚧 **In progress** — implementation exists but the complete checklist has not passed.
- 🧪 **Planned** — no supported installer is published yet.

## Current matrix

| Order | Desktop | openEuler target | Status | Notes |
|---:|---|---:|---|---|
| 1 | Kiran Desktop | 25.09 | ✅ Tested | X410 Desktop mode; Marco, Kiran Panel and Caja verified |
| 2 | UKUI | TBD | 🧪 Planned | Natural next openEuler/Kylin-family experiment |
| 3 | GNOME | TBD | 🧪 Planned | WSLg and nested/full-desktop paths must be evaluated separately |
| 4 | KDE Plasma | TBD | 🧪 Planned | Start with individual WSLg applications, then a separate X410 session |
| 5 | XFCE | TBD | 🧪 Planned | Good lightweight X11 candidate |
| 6 | Deepin Desktop | TBD | 🧪 Planned | Version compatibility must be recorded explicitly |
| 7 | Cinnamon | TBD | 🧪 Planned | Requires window-manager and acceleration checks |
| 8 | MATE | TBD | 🧪 Planned | Shares several components with Kiran |
| 9 | LXQt | TBD | 🧪 Planned | Lightweight Qt/X11 candidate |

## Definition of tested

A desktop can be marked ✅ only after all of these pass:

1. Installation completes on a clean supported openEuler version.
2. The session starts as a non-root user.
3. The correct X11 or Wayland display path is verified.
4. A complete desktop is visibly rendered, not merely left running as background processes.
5. Window manager, panel, file manager and settings daemon are present.
6. Windows shortcut targets the correct WSL distribution and Linux user.
7. Audio, clipboard, scaling and common application launch are checked.
8. Stop and restart leave no duplicate session components.
9. Diagnostics and logs identify failures without manual process hunting.
10. README commands and screenshots match the tested implementation.
