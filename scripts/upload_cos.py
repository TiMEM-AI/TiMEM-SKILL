#!/usr/bin/env python3
"""Upload standalone skill packages to Tencent COS."""
import os
import sys

from qcloud_cos import CosConfig, CosS3Client

cfg = CosConfig(
    Region=os.environ["TENCENT_COS_REGION"],
    SecretId=os.environ["TENCENT_SECRET_ID"],
    SecretKey=os.environ["TENCENT_SECRET_KEY"],
    Scheme="https",
)
client = CosS3Client(cfg)
bucket = os.environ["TENCENT_COS_BUCKET"]
prefix = os.environ["COS_PREFIX"]

for d in os.listdir("dist/standalone"):
    if not d.endswith(".zip"):
        continue
    skill_id = d[:-4]
    key = f"{prefix}/{skill_id}/{d}"
    client.upload_file(
        Bucket=bucket,
        Key=key,
        LocalFilePath=f"dist/standalone/{d}",
        EnableMD5=True,
    )
    client.put_object_acl(Bucket=bucket, Key=key, ACL="public-read")
    print(f"✅ {key}")
