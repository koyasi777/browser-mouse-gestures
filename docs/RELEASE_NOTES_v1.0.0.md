# Browser Mouse Gestures v1.0.0

First public open-source release for Windows, built with AutoHotkey v2.

## Highlights

- Configurable right-button mouse gestures (up to three cardinal directions)
- Right-button + mouse wheel tab switching
- Seven recognition sensitivity levels
- Customizable gesture trails, colors, glow, HUD themes and tray icons
- Support for selected Chromium/Gecko browsers, Windows Notepad, and user-selected apps
- Local configuration; no telemetry or automatic network calls
- Source available in modular form, plus a standalone `.ahk` download

## Install

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Download **Browser_MouseGestures_v1_0_0_Standalone.ahk** from the release assets.
3. Run the `.ahk` and use the tray icon to configure gestures.

The standalone file does not include an AutoHotkey runtime or installer. No compilation required.

## Verification

Windows CI validates both the modular and standalone scripts, runs Python and AutoHotkey helper tests, and verifies the runtime against a previously tested implementation (except for the version comment). Manual Windows operation of the modular build was also confirmed. Browser/app compatibility varies by installation.

---

**日本語:** Windows向けの初回公開版です。AutoHotkey v2をインストールし、リリースの `Browser_MouseGestures_v1_0_0_Standalone.ahk` をダウンロードして実行してください。設定はタスクトレイのアイコンから変更できます。動作確認済みの旧実装から、実行処理は変更していません。
