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
  team: AmSC          # optional
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
