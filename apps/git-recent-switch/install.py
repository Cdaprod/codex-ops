#!/usr/bin/env python3
"""Install the git-recent-switch plugin into a user-scoped plugin directory."""
# Example: python apps/git-recent-switch/install.py --dest ~/.local/share/zsh/plugins

from __future__ import annotations

import argparse
import os
import shutil
import sys
import tempfile
from pathlib import Path
import contextlib


def _parse_args() -> argparse.Namespace:
  """Parse CLI arguments for the installer."""

  default_dest = Path(os.path.expanduser("~/.local/share/zsh/plugins"))
  parser = argparse.ArgumentParser(
      description=(
          "Install the git-recent-switch Zsh plugin into a plugin-safe directory. "
          "The destination should be a directory that contains Zsh plugins."
      )
  )
  parser.add_argument(
      "--dest",
      type=Path,
      default=default_dest,
      help=(
          "Directory that will receive the git-recent-switch plugin. "
          "Defaults to ~/.local/share/zsh/plugins."
      ),
  )
  return parser.parse_args()


def _copy_plugin(src: Path, dest_root: Path) -> Path:
  """Copy the plugin directory to ``dest_root`` safely and idempotently."""

  plugin_name = src.name
  plugin_target = dest_root / plugin_name

  dest_root.mkdir(parents=True, exist_ok=True)

  # Stage the copy inside the destination root to ensure atomic rename.
  staging_parent = Path(
      tempfile.mkdtemp(prefix=f".{plugin_name}-", dir=str(dest_root))
  )
  staging_target = staging_parent / plugin_name

  try:
    shutil.copytree(
        src,
        staging_target,
        ignore=shutil.ignore_patterns("__pycache__", "*.pyc", "*.pyo"),
    )

    if plugin_target.exists():
      shutil.rmtree(plugin_target)

    staging_target.rename(plugin_target)
    staging_parent.rmdir()
  except Exception:
    # Clean up staging area on failure before re-raising.
    with contextlib.suppress(Exception):
      if staging_target.exists():
        shutil.rmtree(staging_target)
      staging_parent.rmdir()
    raise

  return plugin_target


def main() -> int:
  """Entry point for the installer script."""

  args = _parse_args()
  source_dir = Path(__file__).resolve().parent
  destination_root = args.dest.expanduser()

  try:
    installed_path = _copy_plugin(source_dir, destination_root)
  except PermissionError as exc:
    print(f"[grs-install] permission denied: {exc}", file=sys.stderr)
    return 1
  except FileNotFoundError as exc:
    print(f"[grs-install] missing file during install: {exc}", file=sys.stderr)
    return 1
  except OSError as exc:
    print(f"[grs-install] filesystem error: {exc}", file=sys.stderr)
    return 1
  except Exception as exc:  # pragma: no cover - defensive safety net
    print(f"[grs-install] unexpected error: {exc}", file=sys.stderr)
    return 1

  print(f"[grs-install] plugin installed to {installed_path}")
  print(
      "[grs-install] add the directory to your plugin manager or source "
      "init.zsh manually."
  )
  return 0


if __name__ == "__main__":  # pragma: no cover - standard entry guard
  sys.exit(main())
