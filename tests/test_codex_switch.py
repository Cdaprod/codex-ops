import os
import subprocess
import pathlib

def test_default_branch_uses_gh(tmp_path):
    repo = tmp_path
    env = os.environ.copy()
    env.update(
        {
            "GIT_AUTHOR_NAME": "Test",
            "GIT_AUTHOR_EMAIL": "test@example.com",
            "GIT_COMMITTER_NAME": "Test",
            "GIT_COMMITTER_EMAIL": "test@example.com",
        }
    )
    subprocess.run(["git", "init"], cwd=repo, check=True, env=env, stdout=subprocess.PIPE)
    (repo / "file").write_text("a")
    subprocess.run(["git", "add", "file"], cwd=repo, check=True, env=env, stdout=subprocess.PIPE)
    subprocess.run(["git", "commit", "-m", "init"], cwd=repo, check=True, env=env, stdout=subprocess.PIPE)

    gh_stub = repo / "gh"
    gh_stub.write_text(
        "#!/bin/sh\n"
        "if echo \"$@\" | grep -q -- '--state open'; then\n"
        "  exit 0\n"
        "else\n"
        "  echo feature/pr-123\n"
        "fi\n"
    )
    gh_stub.chmod(0o755)
    env["PATH"] = str(repo) + os.pathsep + env["PATH"]

    script = pathlib.Path(__file__).resolve().parent.parent / "apps/codex-switch/codex-switch.sh"
    cmd = f"source {script} && recent_pr_branch"
    result = subprocess.run(["bash", "-c", cmd], cwd=repo, env=env, text=True, capture_output=True, check=True)
    assert result.stdout.strip() == "feature/pr-123"
