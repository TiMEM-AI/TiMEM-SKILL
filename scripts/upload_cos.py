#!/usr/bin/env python3
"""Upload verified standalone skill packages and release ZIPs to Tencent COS."""

from __future__ import annotations

import os
from pathlib import Path

from qcloud_cos import CosConfig, CosS3Client


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"{name} is required for COS publishing")
    return value


def upload_archive(client: CosS3Client, bucket: str, archive: Path, key: str) -> None:
    client.upload_file(
        Bucket=bucket,
        Key=key,
        LocalFilePath=str(archive),
        EnableMD5=True,
    )
    client.put_object_acl(Bucket=bucket, Key=key, ACL="public-read")
    print(f"Uploaded {archive} to cos://{bucket}/{key}")


region = require_env("TENCENT_COS_REGION")
secret_id = require_env("TENCENT_SECRET_ID")
secret_key = require_env("TENCENT_SECRET_KEY")
bucket = require_env("TENCENT_COS_BUCKET")
standalone_prefix = require_env("COS_PREFIX").strip("/")
release_prefix = os.environ.get("RELEASE_COS_PREFIX", "releases").strip("/")

standalone_archives = sorted(Path("dist/standalone").glob("*.zip"))
release_archives = sorted(Path("dist/release").glob("timem-skill-*.zip"))
latest_archive = Path("dist/release/timem-skill-latest.zip")

if not standalone_archives:
    raise RuntimeError("No standalone skill archives were built")
if not latest_archive.is_file() or latest_archive not in release_archives:
    raise RuntimeError("Verified timem-skill-latest.zip is required before COS publishing")

config = CosConfig(
    Region=region,
    SecretId=secret_id,
    SecretKey=secret_key,
    Scheme="https",
)
client = CosS3Client(config)

for archive in standalone_archives:
    skill_id = archive.stem
    upload_archive(client, bucket, archive, f"{standalone_prefix}/{skill_id}/{archive.name}")

for archive in release_archives:
    upload_archive(client, bucket, archive, f"{release_prefix}/{archive.name}")
