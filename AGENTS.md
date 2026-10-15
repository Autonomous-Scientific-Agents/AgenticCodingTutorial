# Repository Guidelines

## Project Structure & Module Organization

This repository publishes an agentic coding tutorial with MkDocs Material. Pages live in `docs/`; `mkdocs.yml` defines navigation, theme, and extensions. `hooks/helpers.py` generates the helpers table from `data/helpers.yml`.

Container tooling lives in `Dockerfile`, `entrypoint.sh`, `run.sh`, `run.ps1`, and `.devcontainer/`. Agent launchers for MAG and ALCF live in `bin/`. GitHub Actions workflows in `.github/workflows/` build and publish the site and container. Treat `site/` as generated output; do not edit or commit it.

## Build, Test, and Development Commands

Use Python 3.12 or newer and uv:

- `uv sync` — install dependencies from `pyproject.toml`.
- `uv run mkdocs serve` — preview the site at `http://127.0.0.1:8000` with live reload.
- `uv run mkdocs build --strict` — build the site and fail on warnings, matching site CI.
- `./run.sh build` — build the tutorial container with Podman or Docker.
- `./run.sh` — open a container shell with the current directory mounted at `/workspace`.

Windows users can use `run.ps1` for container commands.

## Coding Style & Naming Conventions

Use concise Markdown, descriptive headings, and fenced command examples. Name pages with lowercase, hyphenated filenames such as `getting-started.md`; register new pages in `mkdocs.yml`.

Follow existing indentation: four spaces for Python and two for YAML and shell blocks. Use `snake_case` for Python functions, quote shell expansions, and preserve existing `set -euo pipefail` conventions. No formatter or linter is configured.

## Testing Guidelines

There is no dedicated automated test suite, test naming convention, or coverage threshold. For documentation changes, run the strict MkDocs build and preview affected pages, checking links, navigation, and generated tables. For shell changes, run `bash -n` on affected scripts and exercise the relevant launcher with your container engine.

## Commit & Pull Request Guidelines

Use short, descriptive, imperative commit subjects; history includes optional topic prefixes such as `Docs:` and `Container:`. Keep each PR focused on one topic. Describe the change and validation, link relevant issues, and include screenshots when they clarify visual changes.

Follow `CONTRIBUTING.md`: edit only your own helpers entry and mirror resource additions in `docs/resources.md` and `README.md`. Keep both contributing guides consistent. Supply credentials through environment variables; never commit tokens.
