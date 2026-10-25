#!/usr/bin/env python3
"""Build the versioned standalone AutoHotkey release with verified runtime parity.

The v1.0.0 release changes only the human-readable version comment in the
known-working v3.8.3 runtime source. Before verifying its original checksum,
we restore just that comment in memory; all executable code must be identical.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENTRY = ROOT / "MouseGestures.ahk"
MANIFEST = ROOT / "scripts" / "modules.json"
REFERENCE_SHA = ROOT / "tests" / "reference.sha256"
VERSION_FILE = ROOT / "VERSION"
VERSION = VERSION_FILE.read_text(encoding="ascii").strip()
if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", VERSION):
    raise ValueError("VERSION must contain a stable X.Y.Z version")
DIST = ROOT / "dist" / f"Browser_MouseGestures_v{VERSION.replace('.', '_')}_Standalone.ahk"
MARKER = "; === Source modules (the release builder expands these in order) ==="
BASELINE_VERSION = "3.8.3"


def normalized(path: Path) -> str:
    # Reading text also normalizes Windows CRLF to LF on Windows.
    return path.read_text(encoding="utf-8-sig")


def build_text() -> str:
    entry = normalized(ENTRY)
    if entry.count(MARKER) != 1:
        raise ValueError("Entry script must have exactly one module marker")
    prefix = entry.split(MARKER, 1)[0]
    # The entrypoint has one extra blank line before the include marker;
    # remove precisely one newline to recover the original layout.
    if not prefix.endswith("\n\n"):
        raise ValueError("Unexpected entrypoint ending")
    prefix = prefix[:-1]
    modules = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if len(modules) != len(set(modules)) or not modules:
        raise ValueError("Missing/duplicate module names")
    expected_includes = ["#Include %A_ScriptDir%\\" + p.replace("/", "\\") for p in modules]
    actual_includes = [line for line in entry.splitlines() if line.startswith("#Include ")]
    if actual_includes != expected_includes:
        raise ValueError("Entrypoint #Include order differs from the manifest")
    return prefix + "".join(normalized(ROOT / rel) for rel in modules)


def canonical_baseline_text(text: str) -> str:
    """Restore only the release version comment for baseline comparison."""
    release_header = f"; Browser Mouse Gestures v{VERSION} - "
    baseline_header = f"; Browser Mouse Gestures v{BASELINE_VERSION} - "
    matches = [line for line in text.splitlines() if line.startswith(release_header)]
    if len(matches) != 1:
        raise ValueError("Expected exactly one matching release version comment")
    return text.replace(release_header, baseline_header, 1)


def verify(text: str) -> str:
    canonical = canonical_baseline_text(text)
    observed = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    expected = REFERENCE_SHA.read_text(encoding="ascii").strip()
    if observed != expected:
        raise ValueError("Runtime differs from verified v3.8.3 baseline! sha256=" + observed + " expected=" + expected)
    return observed


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Validate parity without writing dist")
    args = parser.parse_args()
    text = build_text()
    digest = verify(text)
    if not args.check:
        DIST.parent.mkdir(parents=True, exist_ok=True)
        # BOM+CRLF for Windows compatibility, matching prior releases.
        DIST.write_bytes(b"\xef\xbb\xbf" + text.replace("\n", "\r\n").encode("utf-8"))
        print(f"Release: {DIST}")
    print(f"PASS: v{VERSION} runtime matches verified v{BASELINE_VERSION} baseline (version comment excluded)")
    print("sha256(canonical baseline):", digest)
    print("sha256(v" + VERSION + " normalized):", hashlib.sha256(text.encode("utf-8")).hexdigest())


if __name__ == "__main__":
    main()
