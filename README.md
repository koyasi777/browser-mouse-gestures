# Browser Mouse Gestures

English | [日本語](README.ja.md)

**Latest release: v1.0.0** · [Release notes](docs/RELEASE_NOTES_v1.0.0.md)

An open-source Windows mouse gesture utility written in AutoHotkey v2. It works at the OS input layer, not as a browser extension. It supports allowlisted Chromium/Firefox-family browsers, Windows Notepad, and apps explicitly selected by the user.

> **Current release:** v1.0.0. The runtime is a behavior-preserving modularization of the previously tested v3.8.3 implementation; only the version comment has changed. Browser compatibility depends on each installed build; an entry in the allowlist is **not** a claim of hands-on verification.

## Features

- Cardinal gestures (up/down/left/right), up to **three directions**, configurable actions.
- Right-button + mouse wheel switches tabs; configurable direction and repeat delay.
- Optional per-browser enable/disable settings, Notepad enabled by default, and a picker for adding running desktop applications.
- Seven recognition sensitivity levels and a customizable HUD.
- Per-gesture colors, adjustable stroke width (1–30 px), optional glow, fast trail recoloring, and 512 px tiled rendering across screens.
- Uses the **window beneath the cursor when the right button is pressed** rather than an unrelated active window; activates the target when sending keyboard shortcuts.
- Local INI configuration: `%APPDATA%\ChromiumMouseGestures\settings.ini`. No network APIs, telemetry, or automatic update checks in the script.

## Installation

1. Install [AutoHotkey v2](https://www.autohotkey.com/) from its official website.
2. Get `Browser_MouseGestures_v1_0_0_Standalone.ahk` from a GitHub Release, or build it with `python scripts/build.py` (output in `dist/`).
3. Exit an older running instance, then launch the new `.ahk` file.
4. Double-click its system tray icon to configure gestures, wheel behavior, supported applications, sensitivity, and appearance.

For development, clone this repository and run `MouseGestures.ahk` directly. All `src/` files must remain next to the entrypoint in their original layout. Python is required **only to build/test**, not to run the app.

## Default gestures

| Input | Action |
|---|---|
| Right button + ↓ | New tab |
| Right button + ↓→ | Close tab |
| Right button + wheel up | Previous tab |
| Right button + wheel down | Next tab |
| Unassigned gesture | No action |
| Right click without movement | Regular context menu |

Gestures run when the right button is released. All bindings are configurable.

## Supported applications and limitations

An application is detected by a combination of process identity, file path, and window class. Bundled support includes Chrome/Chromium forks, Edge, Brave, Vivaldi, Firefox/Gecko forks, Windows Notepad, and user-registered apps. Portable builds and unusual installs may need additional matching rules.

Browser-native mouse gestures, such as Opera's or Vivaldi's, may conflict; disable one of the implementations. Shortcuts are **not universal across apps**. If a shortcut means something different in a custom app, do not assign it. Background windows are **activated** before a shortcut is sent; the script does not silently operate an unfocused window. Avoid running the entire script elevated unless necessary.

See [SECURITY.md](SECURITY.md) for privacy and security considerations.

## Building and testing

```powershell
python -m unittest discover -s tests -v
python scripts/build.py
python scripts/build.py --check

# Windows with official AutoHotkey v2 installed:
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut=UTF-8 /Validate .\MouseGestures.ahk
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut=UTF-8 /Validate .\dist\Browser_MouseGestures_v1_0_0_Standalone.ahk
```

The builder verifies that the v1.0.0 standalone release matches the previously tested v3.8.3 runtime exactly **after restoring only the version comment for comparison**. The original reference hash is retained to detect unintended executable changes. On GitHub Actions, Windows loads the modules and standalone build using AutoHotkey's **`/Validate`** mode (no hotkeys executed), then runs small safe AHK helper tests. These checks do **not** replace manual testing of GUI/input interactions.

See [Architecture](docs/ARCHITECTURE.md) and [Contributing](CONTRIBUTING.md).

## License

[MIT](LICENSE), subject to a final upstream code/icon provenance review before publishing. The AutoHotkey runtime is independently licensed and **not distributed here**.
