# Contributing

Small pull requests are best: one topic per PR.

## Add your topics (helpers)

1. Edit `data/helpers.yml` and change only your own entry.
2. List what people can ask you about under `topics`: tools (for example `Claude Code`, `OpenCode`) and
   research areas (for example `computational chemistry`).
3. Open a pull request. The helpers page and table are generated from this file.

```yaml
- name: Your Name
  email: you@lab.gov
  topics: [Codex, Kokkos, climate modelling]
```

## Add a resource

Add a link to the right section of `docs/resources.md` (and the README, which carries the same list) with
one line saying why it is useful. Prefer official documentation and maintained repositories.

## Edit a page

Pages are Markdown files in `docs/`. Preview locally before opening the PR:

```bash
uv sync
uv run mkdocs serve
```

The build runs with `--strict`, so broken internal links fail the check.

## Change a launcher

Run `python3 -m unittest discover -s tests -v` on Linux or macOS. The tests use a fake container engine
and temporary terminals to check piped input, terminal allocation, argument forwarding, and exit codes.
They do not need model credentials or a running container engine. PowerShell checks run when `pwsh` is
installed; otherwise they are skipped. Also check changed Bash scripts with `bash -n` and exercise the
changed command with Podman or Docker when available.
