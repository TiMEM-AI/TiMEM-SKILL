from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
BUILDER = REPO_ROOT / "scripts" / "build_cos_artifacts.py"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


class CosArtifactBuildTests(unittest.TestCase):
    def test_builds_complete_full_skill_and_preserves_installer_bytes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            project = Path(temp_dir)
            skill = project / "dist" / "full" / "timem-memory-skill"
            (skill / "references" / "future").mkdir(parents=True)
            (skill / "SKILL.md").write_text("---\nname: timem-memory-skill\n---\n", encoding="utf-8")
            (skill / "references" / "workflow.md").write_text("workflow\n", encoding="utf-8")
            (skill / "references" / "future" / "new-file.txt").write_text(
                "future content\n", encoding="utf-8"
            )

            release_dir = project / "dist" / "release"
            release_dir.mkdir(parents=True)
            release = release_dir / "timem-skill-v-test.zip"
            with zipfile.ZipFile(release, "w") as archive:
                archive.writestr("timem-skill/VERSION", "v-test\n")

            ps1_bytes = b"\xef\xbb\xbf<# installer #>\r\n"
            sh_bytes = b"#!/usr/bin/env bash\n"
            (project / "install-all.ps1").write_bytes(ps1_bytes)
            (project / "install-all.sh").write_bytes(sh_bytes)

            output = project / "dist" / "cos"
            subprocess.run(
                [
                    sys.executable,
                    str(BUILDER),
                    "--project-root",
                    str(project),
                    "--output-dir",
                    str(output),
                    "--version",
                    "v-test",
                    "--release-zip",
                    str(release),
                ],
                check=True,
            )

            full_zip = output / "full" / "timem-memory-skill-v-test.zip"
            with zipfile.ZipFile(full_zip) as archive:
                names = set(archive.namelist())
            self.assertIn("timem-memory-skill/SKILL.md", names)
            self.assertIn("timem-memory-skill/references/workflow.md", names)
            self.assertIn("timem-memory-skill/references/future/new-file.txt", names)

            versioned_ps1 = output / "installers" / "v-test" / "install-all.ps1"
            latest_ps1 = output / "installers" / "install-all.ps1"
            self.assertEqual(ps1_bytes, versioned_ps1.read_bytes())
            self.assertEqual(ps1_bytes, latest_ps1.read_bytes())

            manifest_path = output / "manifests" / "release-manifest-v-test.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            paths = {entry["path"] for entry in manifest["full_skill_files"]}
            self.assertEqual(
                {
                    "SKILL.md",
                    "references/workflow.md",
                    "references/future/new-file.txt",
                },
                paths,
            )
            self.assertEqual(sha256(full_zip), manifest["artifacts"]["full_skill"]["sha256"])
            self.assertEqual(sha256(release), manifest["artifacts"]["release"]["sha256"])

            first_full_hash = sha256(full_zip)
            os.utime(skill / "references" / "workflow.md", (2_000_000_000, 2_000_000_000))
            subprocess.run(
                [
                    sys.executable,
                    str(BUILDER),
                    "--project-root",
                    str(project),
                    "--output-dir",
                    str(output),
                    "--version",
                    "v-test",
                    "--release-zip",
                    str(release),
                ],
                check=True,
            )
            self.assertEqual(first_full_hash, sha256(full_zip))

            latest = json.loads((output / "manifests" / "latest.json").read_text(encoding="utf-8"))
            self.assertEqual("v-test", latest["version"])
            self.assertEqual(
                "release-manifest-v-test.json", latest["manifest"]
            )
            self.assertEqual(
                "manifest",
                latest["snapshot_consistency"],
            )
            self.assertEqual(
                "installers/v-test/install-all.ps1",
                latest["artifacts"]["install_all_ps1"],
            )


if __name__ == "__main__":
    unittest.main()
