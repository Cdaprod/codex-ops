"""Tests for rewrite_sponsors_page script."""

import subprocess
import sys


def test_rewrite_sponsors_page(tmp_path):
    funding = tmp_path / "FUNDING.md"
    policy = tmp_path / "sponsors.yaml"
    template = tmp_path / "template.md"
    output = tmp_path / "SPONSORS.md"

    funding.write_text("Funding overview")
    policy.write_text("tiers:\n  - name: Test\n    price: '$1'\n")
    template.write_text("# Sponsors\n\n{{FUNDING}}\n\n{{TIERS}}\n")

    subprocess.run([
        sys.executable,
        "scripts/rewrite_sponsors_page.py",
        "--funding",
        str(funding),
        "--policy",
        str(policy),
        "--template",
        str(template),
        "--output",
        str(output),
    ], check=True)

    content = output.read_text()
    assert "## Test" in content
