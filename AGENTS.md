# Repository Guidelines

## Site and shared content

- This is a MkDocs Material site, not an installable Python package (`tool.uv.package = false`). Edit pages in `docs/` and register new pages in `mkdocs.yml`; `site/` is generated and ignored.
- `hooks/helpers.py` replaces `<!-- helpers-table -->` with a table from `data/helpers.yml` at build time. Edit the YAML, not the rendered table; when adding helper topics, change only your own entry per `CONTRIBUTING.md`.
- Mirror resource additions in `docs/resources.md` and `README.md`. Keep `CONTRIBUTING.md` and `docs/contributing.md` synchronized.

## Setup and verification

- Use Python 3.12+ and `uv sync`, then `uv run mkdocs serve` for preview or `uv run mkdocs build --strict` for the site CI check. No `uv.lock` is currently committed; CI uses `uv sync`, not `uv sync --locked`.
- Launcher tests: `python3 -m unittest discover -s tests -v` on Linux/macOS. They use a fake engine and pseudo-terminals, so no model credentials or running container engine are needed; PowerShell cases skip unless `pwsh` is installed.
- Focused Bash launcher test: `python3 tests/test_launchers.py BashLauncherTests.test_pipe_preserves_stdin_arguments_mount_and_exit_status -v`.
- For changed Bash scripts, also run `bash -n <script>`; exercise the changed launcher with Podman or Docker when available. The automated suite covers `run.sh` and `run.ps1`, not the endpoint wrappers in `bin/`.

## Container and endpoint launchers

- `./run.sh build` builds from the script's repository directory; `./run.sh [command ...]` mounts the caller's current directory at `/workspace`. Windows uses `run.ps1`. Override engine/image with `CONTAINER_ENGINE`/`IMAGE`; `./run.sh code` uses host `PORT` (default 8080).
- Keep `run.sh` and `run.ps1` behavior aligned: stdin stays open (`-i`), while a TTY (`-t`) is allocated only when both input and output are interactive. The passwordless editor must remain bound to host `127.0.0.1`.
- `run.sh` and `entrypoint.sh` cooperate on Linux UID/GID mapping; preserve the drop to user `dev` and named-volume ownership repair. Agent settings/login state persist in named volumes, not in the disposable container.
- All six `{claude,codex,opencode}-{amsc,alcf}` wrappers source `bin/agent-tokens.sh` for shared token handling. Credentials arrive via environment variables (`AMSC_TOKEN`, `ALCF_AI_TOKEN`); prompts require interactive input and output.
- OpenCode wrappers inject providers via `OPENCODE_CONFIG_CONTENT`. Shared `exec_opencode` adds `--standalone` for OpenCode 2 so its private service sees that environment; for supported subcommands the flag goes after the subcommand.
- `Dockerfile` copies `bin/` into `/usr/local/bin/`. Container CI publishes amd64/arm64 images only on `main` changes to `Dockerfile`, `entrypoint.sh`, `bin/**`, or its workflow (or manual dispatch); host launcher edits alone do not trigger it.
