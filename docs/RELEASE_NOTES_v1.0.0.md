# Browser Mouse Gestures v1.0.0

First public open-source release for Windows, built with AutoHotkey v2.

## Highlights

- Configurable right-button mouse gestures (up to three cardinal directions)
- Right-button + mouse wheel tab switching
- Seven recognition sensitivity levels
- Customizable gesture trails, colors, glow, HUD themes and tray icons
- Support for selected Chromium/Gecko browsers, Windows Notepad, and user-selected apps
- Local configuration; no telemetry or automatic network calls in the script
- Modular source code, a portable Windows x64 EXE, and a standalone AHK script

## Download and install

**Recommended — Windows x64 EXE:** Download `BrowserMouseGestures-v1.0.0.exe` from the release Assets and run it. AutoHotkey does **not** need to be installed. Run without administrator privileges unless a specific use case requires elevation.

**Alternative — standalone script:** Install [AutoHotkey v2](https://www.autohotkey.com/), download `Browser_MouseGestures_v1_0_0_Standalone.ahk`, and run it.

Exit any older copy before running the new version. Open Settings from the system tray icon.

## Verification and security

The standalone AHK and the modular source pass Windows CI syntax and helper tests. The release runtime matches a previously tested implementation apart from the version comment. The EXE was separately compiled with official Ahk2Exe using an **AutoHotkey v2.0.27 x64** base and was manually tested on Windows. The current CI **does not automatically build or verify the EXE**. Compatibility varies by browser installation. An unsigned EXE may trigger a SmartScreen warning; verify the download source.

## Licenses

The project script is MIT-licensed. The EXE bundles the AutoHotkey interpreter, separately licensed under **GNU GPL v2**. See [third-party notices](https://github.com/koyasi777/browser-mouse-gestures/blob/main/THIRD_PARTY_NOTICES.md) and [GPL v2](https://github.com/koyasi777/browser-mouse-gestures/blob/main/LICENSES/GPL-2.0.txt). AutoHotkey v2.0.27 source: https://github.com/AutoHotkey/AutoHotkey/tree/v2.0.27

---

**日本語:** Windows x64向け初回正式版です。通常は `BrowserMouseGestures-v1.0.0.exe` をダウンロードしてそのまま起動してください（AutoHotkeyのインストール不要）。ソースを確認・編集したい場合は、AutoHotkey v2をインストールして単一AHK版を使用できます。設定はタスクトレイから変更できます。EXEには別ライセンスのAutoHotkey実行環境が含まれています。
