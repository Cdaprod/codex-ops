#!/usr/bin/env python3
"""Generate docs/SPONSORS.md from funding and sponsor policy data.

Usage:
    python scripts/rewrite_sponsors_page.py --funding docs/FUNDING.md --policy policy/sponsors.yaml --template templates/sponsors_page_prompt.md --output docs/SPONSORS.md

Example:
    python scripts/rewrite_sponsors_page.py \
        --funding docs/FUNDING.md \
        --policy policy/sponsors.yaml \
        --template templates/sponsors_page_prompt.md \
        --output docs/SPONSORS.md
"""

import argparse
import sys
from pathlib import Path

try:
    import yaml
except ModuleNotFoundError as exc:
    print("PyYAML is required to run this script", file=sys.stderr)
    sys.exit(1)

def build_tiers_text(tiers):
    lines = []
    for tier in tiers:
        name = tier.get("name", "Unnamed")
        price = tier.get("price", "")
        lines.append(f"## {name}\nPrice: {price}\n")
    return "\n".join(lines).strip()

def main():
    parser = argparse.ArgumentParser(description="Rewrite sponsors page deterministically.")
    parser.add_argument("--funding", required=True, help="Path to funding overview markdown")
    parser.add_argument("--policy", required=True, help="Path to sponsors YAML policy")
    parser.add_argument("--template", required=True, help="Path to template markdown file")
    parser.add_argument("--output", required=True, help="Path to write sponsors markdown")
    args = parser.parse_args()

    funding_path = Path(args.funding)
    policy_path = Path(args.policy)
    template_path = Path(args.template)
    output_path = Path(args.output)

    if not funding_path.is_file() or not policy_path.is_file() or not template_path.is_file():
        print("Input files are missing", file=sys.stderr)
        return 1

    funding_text = funding_path.read_text().strip()
    policy_data = yaml.safe_load(policy_path.read_text()) or {}
    tiers = policy_data.get("tiers", [])
    tiers_text = build_tiers_text(tiers)
    template = template_path.read_text()

    content = template.replace("{{FUNDING}}", funding_text).replace("{{TIERS}}", tiers_text)
    output_path.write_text(content + "\n")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
