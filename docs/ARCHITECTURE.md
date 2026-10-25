# Architecture: behavior-preserving v3.8.3 extraction

The entrypoint `MouseGestures.ahk` owns the original startup state/global constants, initialization, tray hook, and hotkey declarations. `#Include` imports below preserve the exact original function definitions and order from the known-working v3.8.3 script.

| Module | Purpose |
|---|---|
| `src/Core/WindowTargeting.ahk` | Cursor-under-window selection, allowlisted browser and Notepad identity, validity/activation checks |
| `src/Core/GestureRecognizer.ahk` | Mouse-down tracking, tolerance, stroke recognition and mapping prefixes |
| `src/Core/GestureController.ahk` | Gesture completion and wheel tab navigation |
| `src/Rendering/TrailRenderer.ahk` | 512px tile trail generation, brush, color change and fast recoloring |
| `src/Settings/Appearance.ahk` | RGB helpers, appearance settings persistence, theme selection |
| `src/Rendering/GestureHUD.ahk` | Native Windows HUD creation/updating |
| `src/Rendering/LayeredCanvas.ahk` | Win32 memory bitmap, layered windows, lifecycle cleanup |
| `src/Settings/SettingsPersistence.ahk` | Sensitivity, wheel, app, binding, and color data persistence |
| `src/Icons/IconStorage.ahk` | Preset/custom icon settings, file decoding and validation |
| `src/Icons/EmbeddedIcons.ahk` | Generated large base64 payload, kept separate from application logic |
| `src/Icons/IconUI.ahk` | Tray/window icon update and icon-picker UI |
| `src/UI/SettingsWindow.ahk` | Main configuration GUI and appearance/gesture editing |
| `src/UI/BrowserControls.ahk` | Browser-specific controls |
| `src/UI/RecognitionControls.ahk` | Recognition settings controls |
| `src/UI/WheelControls.ahk` | Wheel settings controls |
| `src/UI/CustomAppControls.ahk` | Notepad, app picker and custom app controls |

**Why split the icons?** The four original preset ICO images are included in `assets/icons/` as actual binaries for easy review, while their existing encoded representation remains isolated in `EmbeddedIcons.ahk`. This maintains a truly standalone `.ahk` release with no changes to the icon decoding code. Future work may consolidate this into a generated-asset workflow, after tests are established.

## Source of truth and release parity

- `scripts/modules.json` is the canonical concatenation order.
- `scripts/build.py` assembles the entrypoint (without `#Include` directives) and modules in that order.
- `tests/reference.sha256` is the hash of the original script after removing the UTF-8 BOM and normalizing line endings. The builder compares against this to prevent changes to the known-working baseline during the first refactor.
- `dist/` is generated. The standalone artifact uses UTF-8 with BOM and Windows CRLF, matching the original distribution style.

## Testing layers

1. **Portable Python checks:** Runtime-code parity, icon binary identity, no duplicate functions, all expected source files included.
2. **Windows CI:** Official AHK v2 `/Validate` for modular and standalone scripts; helper-function unit tests, without running the gesture hook or opening the configuration GUI.
3. **Manual Windows testing (required before a release):** Multi-window focus behavior, wheel gestures, sensitivity changes, HUD/trail color and clipping, multiple monitors, tray icons, Settings/INI migration.

The modular extraction is intentionally conservative. It does not solve pre-existing design debt such as large global state or all GUI controls being free functions. Refactoring those should be a **separate change** with behavioral tests.
