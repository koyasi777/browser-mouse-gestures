# Changelog

## [1.0.0] — First public release (2026-10-26)

- First GitHub release of **Browser Mouse Gestures**, built with AutoHotkey v2.
- Modularized the existing, Windows-tested v3.8.3 gesture implementation without changing its executable behavior. Only the version comment was updated.
- Right-button directional gestures, right-button + wheel tab navigation, seven recognition levels, per-gesture trail colors, customizable HUD and icons, and support for selected browsers, Notepad, and explicitly registered apps.
- Added source modules, local configuration, bilingual documentation, a reproducible single-file builder, Python/AHK tests, and Windows CI.
- Automated build and validation passed on Windows; actual GUI/input behavior also manually confirmed for the modular build.

## Development baseline: v3.8.3 (pre-public release)

- Preserved as the implementation fingerprint in `tests/reference.sha256`.
- The v1.0.0 builder restores only the old version comment for strict baseline verification.
- Prior internal v3.x version history is not a sequence of published GitHub releases.
