#!/usr/bin/env python3
"""Sync shared MCP docs, then build coding and general dist packages."""

from __future__ import annotations

import runpy
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent


def main() -> None:
    runpy.run_path(str(SCRIPTS / "sync-shared-mcp-tools.py"), run_name="__main__")
    runpy.run_path(str(SCRIPTS / "build-coding-standalone.py"), run_name="__main__")
    runpy.run_path(str(SCRIPTS / "build-general-standalone.py"), run_name="__main__")
    print("build-all complete.")


if __name__ == "__main__":
    main()
