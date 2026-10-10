"""MkDocs hook: render data/helpers.yml wherever a page contains <!-- helpers-table -->.

Email display is set by `extra.helper_emails` in mkdocs.yml: "link" (mailto), "obfuscated"
("name at lab dot gov", the default, to keep addresses away from scrapers) or "hidden".
"""

from pathlib import Path

import yaml

MARK = "<!-- helpers-table -->"


def _email(addr: str, mode: str) -> str:
    if mode == "hidden":
        return ""
    if mode == "link":
        return f"[{addr}](mailto:{addr})"
    user, _, domain = addr.partition("@")
    return f"{user} at {domain.replace('.', ' dot ')}"


def on_page_markdown(markdown, page, config, files):
    if MARK not in markdown:
        return markdown
    root = Path(config["config_file_path"]).parent
    people = yaml.safe_load((root / "data" / "helpers.yml").read_text(encoding="utf-8"))
    lead = [p for p in people if p.get("lead")]
    rest = sorted((p for p in people if not p.get("lead")), key=lambda p: p["name"].split()[-1].lower())
    mode = config.get("extra", {}).get("helper_emails", "obfuscated")
    head = "| Name | Team | Ask me about |" + (" Contact |" if mode != "hidden" else "")
    rows = [head, "|---|---|---|" + ("---|" if mode != "hidden" else "")]
    for p in lead + rest:
        name = p["name"] + (" (session lead)" if p.get("lead") else "")
        topics = ", ".join(p.get("topics") or []) or "*coming soon*"
        row = f"| **{name}** | {p.get('team', '')} | {topics} |"
        if mode != "hidden":
            row += f" {_email(p['email'], mode)} |"
        rows.append(row)
    return markdown.replace(MARK, "\n".join(rows))
