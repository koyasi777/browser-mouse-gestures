# Security & privacy / セキュリティとプライバシー

- **Offline by default:** The v1.0.0 source does not intentionally contact network endpoints or implement telemetry/update checking. Review all future changes if this is important to you.
- **Local settings:** `%APPDATA%\ChromiumMouseGestures\settings.ini` stores gesture settings and optional absolute paths to user-registered programs. These paths can identify a machine/user. Do not upload this file in public bug reports or commits.
- **Input permissions:** AutoHotkey simulates keyboard shortcuts to desktop windows. It selects the window under the mouse at right-button press, verifies the target, and activates it before sending; it does not elevate privileges automatically.
- **Scope:** Bundled browser allowlists are best-effort. Unknown apps are not opted in except for Windows Notepad; users can add running windows explicitly. Native gestures of other browser apps may conflict with this tool.
- **Risk:** Untrusted scripts have the ability to send keystrokes, manipulate windows, and access user files. Download from a trusted release and review source before running. Antivirus alerts or binary false positives are not a guarantee of safety.
- **Build artifacts:** The repository distributes AHK source, not a precompiled AutoHotkey runtime. If a third party distributes a compiled EXE, confirm provenance, integrity, and licensing of the bundled runtime.

Please report suspected vulnerabilities privately to repository maintainers when a GitHub security advisory option is available; avoid posting exploitable details or sensitive files in public Issues.
