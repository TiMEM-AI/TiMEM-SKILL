#!/usr/bin/env python3
"""Plan and upload verified TiMEM release artifacts to Tencent COS."""

from __future__ import annotations

import argparse
import hashlib
import json
import mimetypes
import os
from dataclasses import asdict, dataclass
from pathlib import Path


IMMUTABLE_CACHE = "public, max-age=31536000, immutable"
LATEST_CACHE = "no-cache"


@dataclass(frozen=True)
class UploadObject:
    path: Path
    key: str
    content_type: str
    cache_control: str
    immutable: bool

    def serializable(self) -> dict[str, object]:
        data = asdict(self)
        data["path"] = str(self.path)
        return data


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"{name} is required for COS publishing")
    return value


def env_prefix(name: str, default: str | None = None) -> str:
    value = os.environ.get(name, default or "").strip().strip("/")
    if not value:
        raise RuntimeError(f"{name} is required for COS publishing")
    return value


def content_type(path: Path) -> str:
    overrides = {
        ".json": "application/json; charset=utf-8",
        ".ps1": "text/plain; charset=utf-8",
        ".sh": "text/x-shellscript; charset=utf-8",
        ".zip": "application/zip",
    }
    return (
        overrides.get(path.suffix.lower())
        or mimetypes.guess_type(path.name)[0]
        or "application/octet-stream"
    )


def object_for(path: Path, key: str, immutable: bool) -> UploadObject:
    if not path.is_file():
        raise RuntimeError(f"Required publication artifact is missing: {path}")
    return UploadObject(
        path=path,
        key=key,
        content_type=content_type(path),
        cache_control=IMMUTABLE_CACHE if immutable else LATEST_CACHE,
        immutable=immutable,
    )


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify_artifact(
    path: Path, record: object, label: str, *, verify_name: bool = True
) -> None:
    if not path.is_file() or not isinstance(record, dict):
        raise RuntimeError(f"Manifest artifact is missing or invalid: {label}")
    expected_name = str(record.get("file", ""))
    expected_size = record.get("size")
    expected_hash = str(record.get("sha256", ""))
    if (verify_name and expected_name != path.name) or expected_size != path.stat().st_size:
        raise RuntimeError(f"Artifact metadata verification failed for {label}: {path}")
    if expected_hash != file_sha256(path):
        raise RuntimeError(f"Artifact hash verification failed for {label}: {path}")


def build_upload_plan(root: Path) -> list[UploadObject]:
    standalone_prefix = env_prefix("COS_PREFIX")
    full_prefix = env_prefix(
        "COS_FULL_PREFIX", "timem/skills/full/timem-memory-skill"
    )
    release_prefix = env_prefix("RELEASE_COS_PREFIX", "releases")
    installer_prefix = env_prefix("INSTALLER_COS_PREFIX", "installers")

    standalone_dir = root / "dist" / "standalone"
    release_dir = root / "dist" / "release"
    cos_dir = root / "dist" / "cos"
    latest_path = cos_dir / "manifests" / "latest.json"
    if not latest_path.is_file():
        raise RuntimeError("Verified dist/cos/manifests/latest.json is required")
    try:
        latest = json.loads(latest_path.read_text(encoding="utf-8"))
        version = str(latest["version"]).strip()
    except (KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        raise RuntimeError(f"Invalid latest publication manifest: {latest_path}") from error
    if not version or any(character in version for character in "/\\"):
        raise RuntimeError("Publication version is missing or unsafe")

    standalone_archives = sorted(standalone_dir.glob("*.zip"))
    if not standalone_archives:
        raise RuntimeError("No standalone skill archives were built")

    release_version = release_dir / f"timem-skill-{version}.zip"
    release_latest = release_dir / "timem-skill-latest.zip"
    full_version = cos_dir / "full" / f"timem-memory-skill-{version}.zip"
    full_latest = cos_dir / "full" / "timem-memory-skill-latest.zip"
    installer_version_dir = cos_dir / "installers" / version
    installer_latest_dir = cos_dir / "installers"
    manifest_version = cos_dir / "manifests" / f"release-manifest-{version}.json"

    expected_snapshot = {
        "release": f"{release_prefix}/{release_version.name}",
        "full_skill": f"{full_prefix}/{full_version.name}",
        "install_all_ps1": f"{installer_prefix}/{version}/install-all.ps1",
        "install_all_sh": f"{installer_prefix}/{version}/install-all.sh",
        "manifest": f"{release_prefix}/{manifest_version.name}",
    }
    if latest.get("snapshot_consistency") != "manifest" or latest.get(
        "artifacts"
    ) != expected_snapshot:
        raise RuntimeError("latest.json does not describe the immutable COS snapshot")

    try:
        manifest = json.loads(manifest_version.read_text(encoding="utf-8"))
        artifacts = manifest["artifacts"]
    except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        raise RuntimeError(f"Invalid versioned publication manifest: {manifest_version}") from error
    if str(manifest.get("version", "")).strip() != version:
        raise RuntimeError("latest.json and versioned manifest disagree on version")
    verify_artifact(release_version, artifacts.get("release"), "release")
    verify_artifact(full_version, artifacts.get("full_skill"), "full_skill")
    verify_artifact(
        installer_version_dir / "install-all.ps1",
        artifacts.get("install_all_ps1"),
        "install_all_ps1",
    )
    verify_artifact(
        installer_version_dir / "install-all.sh",
        artifacts.get("install_all_sh"),
        "install_all_sh",
    )
    verify_artifact(
        release_latest, artifacts.get("release"), "release_latest", verify_name=False
    )
    verify_artifact(
        full_latest, artifacts.get("full_skill"), "full_skill_latest", verify_name=False
    )
    verify_artifact(
        installer_latest_dir / "install-all.ps1",
        artifacts.get("install_all_ps1"),
        "install_all_ps1_latest",
        verify_name=False,
    )
    verify_artifact(
        installer_latest_dir / "install-all.sh",
        artifacts.get("install_all_sh"),
        "install_all_sh_latest",
        verify_name=False,
    )

    plan: list[UploadObject] = []

    # Immutable version objects are always published and verified first.
    plan.extend(
        [
            object_for(
                release_version,
                f"{release_prefix}/{release_version.name}",
                immutable=True,
            ),
            object_for(
                full_version,
                f"{full_prefix}/{full_version.name}",
                immutable=True,
            ),
            object_for(
                installer_version_dir / "install-all.ps1",
                f"{installer_prefix}/{version}/install-all.ps1",
                immutable=True,
            ),
            object_for(
                installer_version_dir / "install-all.sh",
                f"{installer_prefix}/{version}/install-all.sh",
                immutable=True,
            ),
            object_for(
                manifest_version,
                f"{release_prefix}/{manifest_version.name}",
                immutable=True,
            ),
        ]
    )

    # Existing standalone keys and latest aliases remain backward compatible.
    for archive in standalone_archives:
        skill_id = archive.stem
        plan.append(
            object_for(
                archive,
                f"{standalone_prefix}/{skill_id}/{archive.name}",
                immutable=False,
            )
        )
    plan.extend(
        [
            object_for(
                release_latest,
                f"{release_prefix}/{release_latest.name}",
                immutable=False,
            ),
            object_for(
                full_latest,
                f"{full_prefix}/{full_latest.name}",
                immutable=False,
            ),
            object_for(
                installer_latest_dir / "install-all.ps1",
                f"{installer_prefix}/install-all.ps1",
                immutable=False,
            ),
            object_for(
                installer_latest_dir / "install-all.sh",
                f"{installer_prefix}/install-all.sh",
                immutable=False,
            ),
        ]
    )

    # This pointer is the publication commit point and must be uploaded last.
    plan.append(
        object_for(
            latest_path,
            f"{release_prefix}/latest.json",
            immutable=False,
        )
    )
    return plan


def response_content_length(response: dict[object, object]) -> int | None:
    for name in ("ContentLength", "Content-Length", "content-length"):
        value = response.get(name)
        if value is not None:
            return int(value)
    return None


def response_sha256(response: dict[object, object]) -> str | None:
    for name in (
        "x-cos-meta-sha256",
        "X-Cos-Meta-Sha256",
        "X-COS-META-SHA256",
    ):
        value = response.get(name)
        if value is not None:
            return str(value)
    metadata = response.get("Metadata")
    if isinstance(metadata, dict) and metadata.get("sha256") is not None:
        return str(metadata["sha256"])
    return None


def verify_remote_object(
    response: dict[object, object], item: UploadObject, expected_hash: str
) -> None:
    remote_size = response_content_length(response)
    remote_hash = response_sha256(response)
    if remote_size is None or remote_hash is None:
        raise RuntimeError(f"COS object is missing verification metadata: {item.key}")
    local_size = item.path.stat().st_size
    if remote_size != local_size or remote_hash.lower() != expected_hash.lower():
        raise RuntimeError(
            f"COS object verification failed for {item.key}: "
            f"size={remote_size}/{local_size}, sha256={remote_hash}/{expected_hash}"
        )


def is_not_found(error: Exception) -> bool:
    get_status_code = getattr(error, "get_status_code", None)
    if not callable(get_status_code):
        return False
    return str(get_status_code()) == "404"


def upload_object(client: object, bucket: str, item: UploadObject) -> None:
    local_hash = file_sha256(item.path)
    if item.immutable:
        try:
            existing = client.head_object(Bucket=bucket, Key=item.key)
        except Exception as error:
            if not is_not_found(error):
                raise
        else:
            try:
                verify_remote_object(existing, item, local_hash)
            except RuntimeError as error:
                raise RuntimeError(
                    f"Refusing to overwrite immutable COS object already exists: {item.key}"
                ) from error
            client.put_object_acl(Bucket=bucket, Key=item.key, ACL="public-read")
            print(f"Verified existing immutable object cos://{bucket}/{item.key}")
            return

    client.upload_file(
        Bucket=bucket,
        Key=item.key,
        LocalFilePath=str(item.path),
        EnableMD5=True,
        ContentType=item.content_type,
        CacheControl=item.cache_control,
        Metadata={"x-cos-meta-sha256": local_hash},
    )
    client.put_object_acl(Bucket=bucket, Key=item.key, ACL="public-read")
    head = client.head_object(Bucket=bucket, Key=item.key)
    verify_remote_object(head, item, local_hash)
    print(f"Uploaded and verified {item.path} to cos://{bucket}/{item.key}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument(
        "--plan",
        action="store_true",
        help="Print the ordered upload plan as JSON without requiring COS credentials",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    plan = build_upload_plan(args.root.resolve())
    if args.plan:
        print(
            json.dumps(
                [item.serializable() for item in plan],
                ensure_ascii=False,
                indent=2,
            )
        )
        return

    from qcloud_cos import CosConfig, CosS3Client

    region = require_env("TENCENT_COS_REGION")
    secret_id = require_env("TENCENT_SECRET_ID")
    secret_key = require_env("TENCENT_SECRET_KEY")
    bucket = require_env("TENCENT_COS_BUCKET")
    if bucket != "careerfun-1257357192" or region != "ap-beijing":
        raise RuntimeError("COS target differs from the verified public installer domain")
    config = CosConfig(
        Region=region,
        SecretId=secret_id,
        SecretKey=secret_key,
        Scheme="https",
    )
    client = CosS3Client(config)
    for item in plan:
        upload_object(client, bucket, item)


if __name__ == "__main__":
    main()
