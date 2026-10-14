#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["tomlkit==0.15.1"]
# ///

"""Merge portable Codex preferences and register the native RTK hook."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from collections.abc import MutableMapping
from pathlib import Path

import tomlkit


def merge(destination: MutableMapping, shared: MutableMapping) -> None:
    for key, value in shared.items():
        if isinstance(value, MutableMapping) and isinstance(
            destination.get(key), MutableMapping
        ):
            merge(destination[key], value)
        else:
            destination[key] = value


def sync_preferences(config: Path, shared: Path) -> None:
    if config.is_symlink():
        config = config.resolve(strict=True)
    source = tomlkit.parse(shared.read_text())
    current = config.read_text() if config.exists() else ""
    document = tomlkit.parse(current)
    original_values = document.unwrap()
    merge(document, source)
    if document.unwrap() == original_values and config.exists():
        return
    updated = tomlkit.dumps(document)
    if updated == current:
        return

    with tempfile.NamedTemporaryFile(
        mode="w", dir=config.parent, prefix=".config.toml.", delete=False
    ) as temporary:
        try:
            temporary.write(updated)
            os.chmod(temporary.name, 0o600)
            os.replace(temporary.name, config)
        finally:
            Path(temporary.name).unlink(missing_ok=True)


def has_rtk_hook(path: Path) -> bool:
    if not path.exists():
        return False
    hooks = json.loads(path.read_text()).get("hooks", {}).get("PreToolUse", [])
    return any(
        entry.get("command") == "rtk hook codex"
        for group in hooks
        if group.get("matcher") == "Bash"
        for entry in group.get("hooks", [])
    )


def main() -> None:
    if shutil.which("rtk") is None:
        raise SystemExit("RTK is required; install Homebrew packages first")

    codex_dir = Path.home() / ".codex"
    codex_dir.mkdir(mode=0o700, exist_ok=True)
    shared = Path(__file__).resolve().parent.parent / "config/codex/preferences.toml"
    sync_preferences(codex_dir / "config.toml", shared)

    if not has_rtk_hook(codex_dir / "hooks.json"):
        subprocess.run(["rtk", "init", "-g", "--codex"], check=True)


if __name__ == "__main__":
    main()
