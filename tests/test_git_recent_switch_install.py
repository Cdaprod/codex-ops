"""Tests for the git-recent-switch installer script."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[1]
INSTALL_SCRIPT = REPO_ROOT / "apps" / "git-recent-switch" / "install.py"


@pytest.mark.skipif(not INSTALL_SCRIPT.exists(), reason="installer script missing")
def test_install_script_idempotent(tmp_path: Path) -> None:
  """Running the installer twice should succeed and produce a usable plugin copy."""

  dest_root = tmp_path / "plugins"
  env = os.environ.copy()

  for _ in range(2):
    subprocess.run(
        [sys.executable, str(INSTALL_SCRIPT), "--dest", str(dest_root)],
        check=True,
        cwd=REPO_ROOT,
        env=env,
    )

  installed = dest_root / "git-recent-switch"
  assert installed.is_dir()
  assert (installed / "init.zsh").is_file()
  assert (installed / "functions" / "git-recent-switch").is_file()

  # Ensure the install script does not leave temporary directories behind.
  leftovers = [p for p in dest_root.iterdir() if p.name.startswith(".git-recent-switch-")]
  assert not leftovers
