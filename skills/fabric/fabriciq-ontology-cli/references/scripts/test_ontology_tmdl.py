"""Offline tests for ontology_tmdl.py. Run: python3 -m unittest -v test_ontology_tmdl (from this folder)."""
import base64
import json
import tempfile
import unittest
from pathlib import Path

import ontology_tmdl as ot

EXAMPLE = Path(__file__).resolve().parent.parent / "authoring" / "tmdl-example"
# Minimal database.tmdl payload copied from the Learn ontology-definition page (hand-decoded there too).
LEARN_DATABASE_PAYLOAD = "ZGF0YWJhc2UKCWNvbXBhdGliaWxpdHlMZXZlbDogMTAwMDAwMAo="


def parts_from(**kw):
    return {k.replace("__", "/"): v.encode() if isinstance(v, str) else v for k, v in kw.items()}


class OntologyTmdlTests(unittest.TestCase):
    def test_learn_database_payload_is_tab_indented(self):
        self.assertEqual(base64.b64decode(LEARN_DATABASE_PAYLOAD), b"database\n\tcompatibilityLevel: 1000000\n")

    def test_example_tree_passes(self):
        errors, _ = ot.check_parts(ot._load_parts(EXAMPLE))
        self.assertEqual(errors, [])

    def test_pack_unpack_roundtrip(self):
        original = ot._load_parts(EXAMPLE)
        with tempfile.TemporaryDirectory() as d:
            env = Path(d) / "env.json"
            ot.main(["pack", str(EXAMPLE), "-o", str(env)])
            doc = json.loads(env.read_text())
            self.assertTrue(all(p["payloadType"] == "InlineBase64" for p in doc["definition"]["parts"]))
            out = Path(d) / "out"
            ot.main(["unpack", str(env), str(out)])
            self.assertEqual(ot._load_parts(out), original)

    def test_space_indentation_is_an_error(self):
        parts = ot._load_parts(EXAMPLE)
        parts["database.tmdl"] = b"database\n    compatibilityLevel: 1000000\n"
        errors, _ = ot.check_parts(parts)
        self.assertTrue(any("space indentation" in e for e in errors))

    def test_missing_required_parts(self):
        errors, _ = ot.check_parts({"database.tmdl": b"database\n\tcompatibilityLevel: 1000000\n"})
        self.assertIn("missing required part: .platform", errors)
        errors, _ = ot.check_parts({".platform": b'{"metadata":{"type":"Ontology"},"config":{"version":"2.0"}}'})
        self.assertIn("missing required part: database.tmdl", errors)

    def test_wrong_type_and_bad_path(self):
        parts = ot._load_parts(EXAMPLE)
        parts[".platform"] = b'{"metadata":{"type":"Lakehouse"}}'
        parts["entities\\bad.tmdl"] = b"entity bad\n"
        errors, _ = ot.check_parts(parts)
        self.assertTrue(any("metadata.type" in e for e in errors))
        self.assertTrue(any("backslash" in e for e in errors))

    def test_dax_explicit_metric_flagged(self):
        parts = ot._load_parts(EXAMPLE)
        parts["metrics/Total.tmdl"] = b"metric Total\n\texpression\n\t\tdialect: DAX\n\t\texpression: SUM(x)\n"
        errors, _ = ot.check_parts(parts)
        self.assertTrue(any("DAX" in e for e in errors))

    def test_generation_detection(self):
        self.assertEqual(ot.detect_generation(ot._load_parts(EXAMPLE)), "generation-2-tmdl")
        legacy = parts_from(**{"definition.json": "{}", "EntityTypes__1__definition.json": "{}"})
        self.assertEqual(ot.detect_generation(legacy), "generation-1-json")
        self.assertEqual(ot.detect_generation({}), "unknown")

    def test_legacy_layout_skips_tmdl_rules(self):
        legacy = parts_from(**{"definition.json": "{}", "EntityTypes__1__definition.json": "{}"})
        errors, warnings = ot.check_parts(legacy)
        self.assertEqual(errors, [])
        self.assertTrue(any("legacy" in w for w in warnings))


if __name__ == "__main__":
    unittest.main()
