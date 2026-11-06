"""Check that each installable personal memory entry ships the same consent policy."""
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "skills/timem-project-memory/SKILL.md"


class SessionSavePolicyTest(unittest.TestCase):
    def test_installed_entry_points_match_project_consent_steps(self):
        source = PROJECT.read_text(encoding="utf-8")
        policy = source.split("## 本会话的逐条保存开关\n", 1)[1].split("\n用户确认保存后", 1)[0].strip()
        self.assertTrue(policy.startswith("1. "))
        for entry in (
            "dist/full/timem-memory-skill", "dist/standalone/timem-memory-skill",
            "dist/full/timem-coding-memory", "dist/standalone/timem-coding-memory",
            "dist/full/timem-general-memory", "dist/standalone/timem-general-memory",
            "skills/timem-writing-memory",
        ):
            with self.subTest(entry=entry):
                text = (ROOT / entry / "SKILL.md").read_text(encoding="utf-8")
                self.assertIn(policy, text)
                self.assertNotIn("授权在本次保存后用尽", text)
