from __future__ import annotations

import json
import hashlib
import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
UPLOADER = REPO_ROOT / "scripts" / "upload_cos.py"


def load_uploader_module():
    spec = importlib.util.spec_from_file_location("upload_cos", UPLOADER)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def artifact_record(path: Path) -> dict[str, object]:
    return {
        "file": path.name,
        "size": path.stat().st_size,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


class CosUploadPlanTests(unittest.TestCase):
    def test_latest_pointer_is_published_after_versioned_and_compatibility_objects(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            files = {
                "dist/standalone/example.zip": b"standalone",
                "dist/release/timem-skill-v-test.zip": b"release-version",
                "dist/release/timem-skill-latest.zip": b"release-version",
                "dist/cos/full/timem-memory-skill-v-test.zip": b"full-version",
                "dist/cos/full/timem-memory-skill-latest.zip": b"full-version",
                "dist/cos/installers/v-test/install-all.ps1": b"ps-version",
                "dist/cos/installers/v-test/install-all.sh": b"sh-version",
                "dist/cos/installers/install-all.ps1": b"ps-version",
                "dist/cos/installers/install-all.sh": b"sh-version",
                "dist/cos/manifests/latest.json": json.dumps(
                    {
                        "schema_version": 1,
                        "version": "v-test",
                        "snapshot_consistency": "manifest",
                        "artifacts": {
                            "release": "releases/timem-skill-v-test.zip",
                            "full_skill": "timem/skills/full/timem-memory-skill/timem-memory-skill-v-test.zip",
                            "install_all_ps1": "installers/v-test/install-all.ps1",
                            "install_all_sh": "installers/v-test/install-all.sh",
                            "manifest": "releases/release-manifest-v-test.json",
                        },
                    }
                ).encode("utf-8"),
            }
            for relative, content in files.items():
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content)

            manifest = {
                "schema_version": 1,
                "version": "v-test",
                "artifacts": {
                    "release": artifact_record(
                        root / "dist/release/timem-skill-v-test.zip"
                    ),
                    "full_skill": artifact_record(
                        root
                        / "dist/cos/full/timem-memory-skill-v-test.zip"
                    ),
                    "install_all_ps1": artifact_record(
                        root
                        / "dist/cos/installers/v-test/install-all.ps1"
                    ),
                    "install_all_sh": artifact_record(
                        root
                        / "dist/cos/installers/v-test/install-all.sh"
                    ),
                },
                "full_skill_files": [],
            }
            manifest_path = (
                root
                / "dist/cos/manifests/release-manifest-v-test.json"
            )
            manifest_path.write_text(
                json.dumps(manifest), encoding="utf-8"
            )

            environment = os.environ.copy()
            environment.update(
                {
                    "COS_PREFIX": "timem/skills/standalone",
                    "COS_FULL_PREFIX": "timem/skills/full/timem-memory-skill",
                    "RELEASE_COS_PREFIX": "releases",
                    "INSTALLER_COS_PREFIX": "installers",
                }
            )
            result = subprocess.run(
                [
                    sys.executable,
                    str(UPLOADER),
                    "--plan",
                    "--root",
                    str(root),
                ],
                check=False,
                capture_output=True,
                text=True,
                env=environment,
            )
            self.assertEqual(0, result.returncode, result.stderr)
            plan = json.loads(result.stdout)
            keys = [item["key"] for item in plan]

            self.assertEqual("releases/latest.json", keys[-1])
            self.assertLess(
                keys.index("releases/timem-skill-v-test.zip"),
                keys.index("releases/timem-skill-latest.zip"),
            )
            self.assertLess(
                keys.index(
                    "timem/skills/full/timem-memory-skill/timem-memory-skill-v-test.zip"
                ),
                keys.index(
                    "timem/skills/full/timem-memory-skill/timem-memory-skill-latest.zip"
                ),
            )
            self.assertLess(
                keys.index("installers/v-test/install-all.ps1"),
                keys.index("installers/install-all.ps1"),
            )
            self.assertEqual("no-cache", plan[-1]["cache_control"])

            # A build output changed after manifest creation must not be publishable.
            (root / "dist/cos/full/timem-memory-skill-v-test.zip").write_bytes(
                b"FULL-version"
            )
            tampered = subprocess.run(
                [
                    sys.executable,
                    str(UPLOADER),
                    "--plan",
                    "--root",
                    str(root),
                ],
                check=False,
                capture_output=True,
                text=True,
                env=environment,
            )
            self.assertNotEqual(0, tampered.returncode)
            self.assertIn("hash verification failed", tampered.stderr)

    def test_versioned_object_is_never_overwritten(self) -> None:
        uploader = load_uploader_module()
        with tempfile.TemporaryDirectory() as temp_dir:
            artifact = Path(temp_dir) / "release.zip"
            artifact.write_bytes(b"new-release")
            item = uploader.object_for(artifact, "releases/release.zip", immutable=True)

            class ExistingObjectClient:
                uploads = 0

                def head_object(self, **_kwargs):
                    return {
                        "Content-Length": str(len(b"different-release")),
                        "x-cos-meta-sha256": hashlib.sha256(
                            b"different-release"
                        ).hexdigest(),
                    }

                def upload_file(self, **_kwargs):
                    self.uploads += 1

            client = ExistingObjectClient()
            with self.assertRaisesRegex(RuntimeError, "immutable COS object already exists"):
                uploader.upload_object(client, "bucket", item)
            self.assertEqual(0, client.uploads)

    def test_upload_verification_requires_remote_size_and_sha256(self) -> None:
        uploader = load_uploader_module()
        with tempfile.TemporaryDirectory() as temp_dir:
            artifact = Path(temp_dir) / "latest.zip"
            artifact.write_bytes(b"latest")
            item = uploader.object_for(artifact, "releases/latest.zip", immutable=False)

            class MissingMetadataClient:
                upload_args = None

                def upload_file(self, **kwargs):
                    self.upload_args = kwargs
                    return None

                def put_object_acl(self, **_kwargs):
                    return None

                def head_object(self, **_kwargs):
                    return {}

            client = MissingMetadataClient()
            with self.assertRaisesRegex(RuntimeError, "missing verification metadata"):
                uploader.upload_object(client, "bucket", item)
            self.assertEqual(
                hashlib.sha256(b"latest").hexdigest(),
                client.upload_args["Metadata"]["x-cos-meta-sha256"],
            )


if __name__ == "__main__":
    unittest.main()
