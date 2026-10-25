from __future__ import annotations
import base64
import hashlib
import json
import re
import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import build


class ReleaseParityTests(unittest.TestCase):
    def test_standalone_exact_v383_parity(self):
        content = build.build_text()
        self.assertEqual(hashlib.sha256(content.encode("utf-8")).hexdigest(),
                         (ROOT / "tests/reference.sha256").read_text().strip())
        self.assertEqual(content.count("#Requires AutoHotkey v2.0"), 1)
        self.assertIn("SetWinDelay(0)", content)
        self.assertNotIn("#Include", content)

    def test_no_duplicate_functions_in_extracted_code(self):
        code = build.build_text()
        functions = re.findall(r"^([A-Za-z_]\w*)\([^\n]*\)\s*\{\s*$", code, re.M)
        self.assertGreater(len(functions), 110)
        folded = [name.casefold() for name in functions]
        self.assertEqual(len(folded), len(set(folded)))

    def test_binary_icons_match_embedded_data(self):
        code = (ROOT / "src/Icons/EmbeddedIcons.ahk").read_text(encoding="utf-8")
        matches = re.findall(r'case "(cursor|gesture|orbit|spark)":(.*?)(?=\n\s*case "|\n\s*\})', code, re.S)
        self.assertEqual(len(matches), 4)
        for name, block in matches:
            fragments = re.findall(r'\bdata \.= "([A-Za-z0-9+/=]+)"', block)
            icon = base64.b64decode("".join(fragments), validate=True)
            self.assertEqual((ROOT / "assets/icons" / (name + ".ico")).read_bytes(), icon)
            self.assertEqual(icon[:4], b"\x00\x00\x01\x00")

    def test_every_module_present(self):
        modules = json.loads((ROOT / "scripts/modules.json").read_text())
        self.assertEqual(len(modules), 16)
        for module in modules:
            with self.subTest(module=module):
                self.assertTrue((ROOT / module).is_file())
                self.assertTrue(module.startswith("src/"))


if __name__ == "__main__":
    unittest.main()
