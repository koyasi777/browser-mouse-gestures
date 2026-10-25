# Contributing / コントリビューション

Thanks for contributing. Please file an Issue with Windows version, AutoHotkey v2 version, affected application, what was expected, and what actually happened (plus steps to reproduce). **Never attach personal `settings.ini` without removing executable paths and other local information.**

## Development setup

1. Install Python 3.10+ and official AutoHotkey v2 (on Windows).
2. Run `python -m unittest discover -s tests -v`.
3. Run `python scripts/build.py --check`.
4. After changes, run `python scripts/build.py` to create `dist/Browser_MouseGestures_v3_8_3_Standalone.ahk`.
5. Use AutoHotkey `/ErrorStdOut=UTF-8 /Validate` to syntax-check both the source entrypoint and single-file release.
6. **Manually test**: regular right-click, ↓, ↓→, unregistered gestures, right-button+wheel, focused/unfocused target windows, Win11 Notepad, tiled trails crossing monitor boundaries, recoloring, config migration, tray/window icons and UI settings.

## Important: strict refactor baseline

`scripts/build.py` currently compares the generated source to the original v3.8.3 fingerprint in `tests/reference.sha256`. This guards **exact runtime-source parity** for the initial refactor. For later feature changes, intentionally update the baseline/test strategy in a dedicated, reviewed commit (do not casually replace a failed hash), add tests, and update `CHANGELOG.md` and version numbers.

## Updating preset icons

`assets/icons/*.ico` are inspectable copies extracted from `src/Icons/EmbeddedIcons.ahk`. If replacing an icon, regenerate the embedded script data and verify binary parity in `tests/test_build.py`. Review the rights and provenance of any contributed artwork.

## Quality and security

- Keep script code compatible with **AutoHotkey v2 only** and `#Warn` enabled.
- Do not add network calls, telemetry, dependencies, or privileged actions without a clear opt-in and explicit disclosure.
- Avoid `WinActivate` without verifying the saved mouse-down target window.
- Do not change the way `settings.ini` is interpreted without a backward-compatible migration.
- Prefer narrowly scoped input hooks; never intercept all apps by default.
- All changes should pass CI, but CI cannot prove mouse/GUI correctness, so include a manual testing note in PRs.
