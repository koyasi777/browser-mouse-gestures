#!/usr/bin/env python3
"""Build the single-file AutoHotkey release without changing the v3.8.3 runtime logic.

The include files contain consecutive, unchanged regions from the tested
v3.8.3 script. Concatenating them after the entrypoint reconstructs the
original source exactly (apart from its UTF-8 BOM and CRLF normalization).
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENTRY = ROOT / "MouseGestures.ahk"
MANIFEST = ROOT / "scripts" / "modules.json"
REFERENCE_SHA = ROOT / "tests" / "reference.sha256"
DIST = ROOT / "dist" / "Browser_MouseGestures_v3_8_3_Standalone.ahk"
MARKER = "; === Source modules (the release builder expands these in order) ==="


def normalized(path: Path) -> str:
    # pathlib text mode also normalizes CRLF to LF on Windows.
    return path.read_text(encoding="utf-8-sig")


def build_text() -> str:
    entry = normalized(ENTRY)
    if entry.count(MARKER) != 1:
        raise ValueError("Entry script must have exactly one module marker")
    prefix = entry.split(MARKER, 1)[0]
    # Source entrypoint intentionally has an extra empty line before the
    # include marker; strip precisely that line to recover original source.
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


def verify(text: str) -> str:
    observed = hashlib.sha256(text.encode("utf-8")).hexdigest()
    expected = REFERENCE_SHA.read_text(encoding="ascii").strip()
    if observed != expected:
        raise ValueError("Refactor changed release code! sha256=" + observed + " expected=" + expected)
    return observed


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Validate parity without writing dist")
    args = parser.parse_args()
    text = build_text()
    digest = verify(text)
    if not args.check:
        DIST.parent.mkdir(parents=True, exist_ok=True)
        # BOM+CRLF retained for best Windows compatibility, just as in 3.8.3.
        DIST.write_bytes(b"\xef\xbb\xbf" + text.replace("\n", "\r\n").encode("utf-8"))
        print(f"Release: {DIST}")
    print("PASS: standalone runtime source exactly matches v3.8.3 (UTF-8 normalized)")
    print("sha256(normalized):", digest)


if __name__ == "__main__":
    main()
