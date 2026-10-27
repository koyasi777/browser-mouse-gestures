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

**Recommended: Windows x64 EXE (no AutoHotkey installation required)**

1. Download `BrowserMouseGestures-v1.0.0.exe` from the [v1.0.0 release](https://github.com/koyasi777/browser-mouse-gestures/releases/tag/v1.0.0).
2. Exit any older running copy of Browser Mouse Gestures, then run the EXE normally (without administrator privileges).
3. Double-click its system tray icon to configure gestures, applications, sensitivity, and appearance.

**Alternative: standalone AutoHotkey v2 script**

1. Install [AutoHotkey v2](https://www.autohotkey.com/) from its official website.
2. Download `Browser_MouseGestures_v1_0_0_Standalone.ahk` from the same release, or build it with `python scripts/build.py` (output in `dist/`).
3. Exit any older running copy, then launch the `.ahk` file. Configure it using the system tray icon.

The EXE was built manually using the official Ahk2Exe and the **AutoHotkey v2.0.27 x64** base, then manually tested on Windows. GitHub Actions currently validates and packages the AHK script; it **does not build or test this EXE**. Unsigned executables may produce a Windows SmartScreen warning.

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

The project's original script and artwork are intended to be distributed under [MIT](LICENSE), subject to confirmation of rights and provenance. The optional prebuilt EXE embeds **AutoHotkey v2.0.27**, which is separately licensed under **GNU GPL v2**. See [Third-party notices](THIRD_PARTY_NOTICES.md) and [GPL-2.0 license text](LICENSES/GPL-2.0.txt). The MIT license is **not** a claim that the bundled AutoHotkey interpreter is MIT-licensed.
