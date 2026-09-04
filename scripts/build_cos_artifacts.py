#!/usr/bin/env python3
"""Build verified COS publication artifacts from one repository snapshot."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
from pathlib import Path

from deterministic_zip import iter_package_files, write_deterministic_zip


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def artifact_record(path: Path) -> dict[str, object]:
    return {
        "file": path.name,
        "size": path.stat().st_size,
        "sha256": file_sha256(path),
    }


def build_artifacts(
    project_root: Path, output_dir: Path, version: str, release_zip: Path
) -> None:
    full_skill = project_root / "dist" / "full" / "timem-memory-skill"
    powershell_installer = project_root / "install-all.ps1"
    shell_installer = project_root / "install-all.sh"

    required = [
        full_skill / "SKILL.md",
        powershell_installer,
        shell_installer,
        release_zip,
    ]
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise SystemExit(f"Missing required COS build inputs: {', '.join(missing)}")
    if not version.strip() or any(character in version for character in "/\\"):
        raise SystemExit("Version must be non-empty and cannot contain path separators")

    if output_dir.exists():
        shutil.rmtree(output_dir)
    full_output = output_dir / "full"
    installers_output = output_dir / "installers"
    manifests_output = output_dir / "manifests"
    manifests_output.mkdir(parents=True, exist_ok=True)

    full_zip = full_output / f"timem-memory-skill-{version}.zip"
    full_latest = full_output / "timem-memory-skill-latest.zip"
    write_deterministic_zip(full_skill, full_zip)
    shutil.copyfile(full_zip, full_latest)

    versioned_installers = installers_output / version
    versioned_installers.mkdir(parents=True, exist_ok=True)
    installers_output.mkdir(parents=True, exist_ok=True)
    for source in (powershell_installer, shell_installer):
        shutil.copyfile(source, versioned_installers / source.name)
        shutil.copyfile(source, installers_output / source.name)

    full_skill_files = [
        {
            "path": path.relative_to(full_skill).as_posix(),
            "size": path.stat().st_size,
            "sha256": file_sha256(path),
        }
        for path in iter_package_files(full_skill)
    ]
    manifest = {
        "schema_version": 1,
        "version": version,
        "artifacts": {
            "release": artifact_record(release_zip),
            "full_skill": artifact_record(full_zip),
            "install_all_ps1": artifact_record(powershell_installer),
            "install_all_sh": artifact_record(shell_installer),
        },
        "full_skill_files": full_skill_files,
    }
    manifest_name = f"release-manifest-{version}.json"
    manifest_path = manifests_output / manifest_name
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    release_prefix = os.environ.get("RELEASE_COS_PREFIX", "releases").strip("/")
    full_prefix = os.environ.get(
        "COS_FULL_PREFIX", "timem/skills/full/timem-memory-skill"
    ).strip("/")
    installer_prefix = os.environ.get("INSTALLER_COS_PREFIX", "installers").strip(
        "/"
    )
    latest = {
        "schema_version": 1,
        "version": version,
        "manifest": manifest_name,
        "release": f"timem-skill-{version}.zip",
        "full_skill": full_zip.name,
        # Cross-artifact consistency is guaranteed by resolving this pointer to
        # immutable keys. The compatibility `*-latest` aliases are each atomic,
        # but are intentionally not a multi-object transaction.
        "snapshot_consistency": "manifest",
        "artifacts": {
            "release": f"{release_prefix}/{release_zip.name}",
            "full_skill": f"{full_prefix}/{full_zip.name}",
            "install_all_ps1": f"{installer_prefix}/{version}/install-all.ps1",
            "install_all_sh": f"{installer_prefix}/{version}/install-all.sh",
            "manifest": f"{release_prefix}/{manifest_name}",
        },
    }
    (manifests_output / "latest.json").write_text(
        json.dumps(latest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    print(f"Built COS artifacts for {version} in {output_dir}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--project-root", type=Path, default=Path(__file__).resolve().parents[1]
    )
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--version", required=True)
    parser.add_argument("--release-zip", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    project_root = args.project_root.resolve()
    output_dir = (
        args.output_dir.resolve()
        if args.output_dir
        else project_root / "dist" / "cos"
    )
    release_zip = (
        args.release_zip.resolve()
        if args.release_zip
        else project_root / "dist" / "release" / f"timem-skill-{args.version}.zip"
    )
    build_artifacts(project_root, output_dir, args.version, release_zip)


if __name__ == "__main__":
    main()
