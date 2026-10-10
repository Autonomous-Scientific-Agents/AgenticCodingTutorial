"""MkDocs hook: render data/helpers.yml wherever a page contains <!-- helpers-table -->.

Each name links to the helper's email address; the entry marked `lead: true` is listed first,
the rest are sorted by surname.
"""

from pathlib import Path

import yaml

MARK = "<!-- helpers-table -->"


def on_page_markdown(markdown, page, config, files):
    if MARK not in markdown:
        return markdown
    root = Path(config["config_file_path"]).parent
    people = yaml.safe_load((root / "data" / "helpers.yml").read_text(encoding="utf-8"))
    lead = [p for p in people if p.get("lead")]
    rest = sorted((p for p in people if not p.get("lead")), key=lambda p: p["name"].split()[-1].lower())
    rows = ["| Name | Ask me about |", "|---|---|"]
    for p in lead + rest:
        topics = ", ".join(p.get("topics") or [])
        rows.append(f"| [{p['name']}](mailto:{p['email']}) | {topics} |")
    return markdown.replace(MARK, "\n".join(rows))
