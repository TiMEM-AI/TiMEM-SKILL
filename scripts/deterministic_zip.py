#!/usr/bin/env python3
"""Create byte-reproducible ZIP archives for TiMEM release publishing."""

from __future__ import annotations

import argparse
import stat
import zipfile
from pathlib import Path


EXCLUDED_NAMES = {".DS_Store", "Thumbs.db"}
EXCLUDED_DIRS = {"__pycache__"}


def iter_package_files(root: Path) -> list[Path]:
    files: list[Path] = []
    for path in root.rglob("*"):
        relative = path.relative_to(root)
        if any(part in EXCLUDED_DIRS for part in relative.parts):
            continue
        if path.is_file() and path.name not in EXCLUDED_NAMES and path.suffix != ".pyc":
            files.append(path)
    return sorted(files, key=lambda item: item.relative_to(root).as_posix())


def write_deterministic_zip(
    source: Path, destination: Path, archive_root: str | None = None
) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    root_name = archive_root or source.name
    with zipfile.ZipFile(
        destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9
    ) as archive:
        for path in iter_package_files(source):
            archive_name = f"{root_name}/{path.relative_to(source).as_posix()}"
            info = zipfile.ZipInfo(archive_name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            executable = bool(path.stat().st_mode & 0o111)
            permissions = 0o755 if executable else 0o644
            info.external_attr = (stat.S_IFREG | permissions) << 16
            archive.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--archive-root")
    args = parser.parse_args()
    write_deterministic_zip(
        args.source.resolve(),
        args.destination.resolve(),
        args.archive_root,
    )


if __name__ == "__main__":
    main()
