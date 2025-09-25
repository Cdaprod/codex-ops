"""Tests for the git-recent-switch Zsh plugin."""

from __future__ import annotations

import os
import shutil
import subprocess
import textwrap
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[1]
PLUGIN_INIT = (REPO_ROOT / "apps" / "git-recent-switch" / "init.zsh").resolve()


def _run(cmd: list[str], *, cwd: Path, env: dict[str, str]) -> None:
  """Execute a command with basic error handling."""
  subprocess.run(cmd, cwd=cwd, env=env, check=True)


@pytest.mark.skipif(shutil.which("zsh") is None, reason="zsh shell is required for plugin tests")
def test_git_recent_switch_tty_menu(tmp_path: Path) -> None:
  """The fallback menu should switch to the selected branch without fzf."""
  repo_dir = tmp_path / "repo"
  home_dir = tmp_path / "home"
  repo_dir.mkdir()
  home_dir.mkdir()

  env = os.environ.copy()
  env.update(
    {
      "HOME": str(home_dir),
      "PATH": "/usr/bin:/bin",
      "GIT_AUTHOR_NAME": "Test User",
      "GIT_AUTHOR_EMAIL": "tester@example.com",
      "GIT_COMMITTER_NAME": "Test User",
      "GIT_COMMITTER_EMAIL": "tester@example.com",
    }
  )
  env.pop("ZDOTDIR", None)

  _run(["git", "init"], cwd=repo_dir, env=env)
  _run(["git", "checkout", "-b", "main"], cwd=repo_dir, env=env)

  (repo_dir / "README.md").write_text("main\n", encoding="utf-8")
  _run(["git", "add", "README.md"], cwd=repo_dir, env=env)
  _run(["git", "commit", "-m", "init"], cwd=repo_dir, env=env)

  _run(["git", "checkout", "-b", "feature/demo"], cwd=repo_dir, env=env)
  (repo_dir / "feature.txt").write_text("feature\n", encoding="utf-8")
  _run(["git", "add", "feature.txt"], cwd=repo_dir, env=env)
  _run(["git", "commit", "-m", "feature"], cwd=repo_dir, env=env)

  _run(["git", "checkout", "main"], cwd=repo_dir, env=env)
  _run(["git", "checkout", "-b", "bugfix/handoff"], cwd=repo_dir, env=env)

  shell_script = textwrap.dedent(
    f"""
    set -e
    source '{PLUGIN_INIT}'
    cd '{repo_dir.resolve()}'
    git switch bugfix/handoff >/dev/null
    git-recent-switch <<< '2'
    """
  )

  result = subprocess.run(
    ["zsh", "-c", shell_script],
    env=env,
    capture_output=True,
    text=True,
    check=True,
  )

  assert "[grs] fzf unavailable; showing numbered menu." in result.stdout
  assert "2) main" in result.stdout
  assert "[grs] switched to main" in result.stdout

  head = subprocess.check_output(
    ["git", "rev-parse", "--abbrev-ref", "HEAD"],
    cwd=repo_dir,
    env=env,
    text=True,
  ).strip()
  assert head == "main"
