# Custom LLM endpoints

Point your coding agent at Argonne-hosted backends: argo-proxy (ANL), argo-shim (ALCF compute), ALCF Inference Endpoints (open-weight models), or i2-core (AmSC commercial models).

| Backend | Network | Auth | Tools covered here | Official docs |
|---|---|---|---|---|
| **argo-proxy** | ANL internal / VPN | ANL username | Claude Code, Codex CLI, OpenCode, Kilo Code | [argo-proxy ReadTheDocs](https://argo-proxy.readthedocs.io) |
| **argo-shim** | ALCF machine (UAN/login) | CELS SSH key | Claude Code, Codex CLI | [argo-shim README](https://github.com/n-getty/argo-shim) |
| **ALCF Inference** | Public (Globus auth) | Globus token | All five (Cursor and Kilo Code untested) | [ALCF Inference Endpoints](https://docs.alcf.anl.gov/services/inference-endpoints) |
| **i2-core** | Public | API key | OpenCode | [API key manager](https://api.i2-core.american-science-cloud.org/) |

!!! note "MAG (Model Access Gateway)"
    Genesis Mission teams already have model access through the [AmSC Model Access Gateway (MAG)](https://docs.amsc.energy.gov/model-access-gateway/). MAG docs cover setup for Claude Code and Codex CLI directly; this page covers argo-proxy/argo-shim/ALCF self-hosted alternatives.

---

## argo-proxy

A multi-format gateway to Argo on the ANL network. Translates OpenAI, Anthropic, and Google GenAI wire formats.

!!! warning "ANL network only"
    argo-proxy reaches the Argo API only from the ANL internal network or via VPN on an ANL-managed machine. Your argo-proxy instance must run on-premises.

### Install and run

```bash
pip install argo-proxy
argo-proxy config init     # interactive setup
argo-proxy serve
```

`argo-proxy config init` picks a free port and writes `~/.config/argoproxy/config.yaml`. The examples below
use `44497`; replace it with the port in your config or in the startup output.

### Claude Code

Add to `~/.claude/settings.json` (current Claude Code no longer has `claude config set -g`):

```json
{
  "apiKeyHelper": "echo your-anl-username",
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:44497",
    "CLAUDE_CODE_SKIP_ANTHROPIC_AUTH": "1"
  }
}
```

The base URL is the proxy root, without `/v1`: Claude Code appends `/v1/messages` itself. The argo-proxy docs
say `CLAUDE_CODE_SKIP_ANTHROPIC_AUTH=1` is required; it skips Anthropic's default sign-in flow.

### Codex CLI

Add to `~/.codex/config.toml`:

```toml
model = "argo:gpt-5"
model_provider = "argo"

[model_providers.argo]
name = "Argo Proxy"
base_url = "http://localhost:44497/v1"
env_key = "ARGO_API_KEY"
wire_api = "responses"
```

Export the API key:

```bash
export ARGO_API_KEY="your-anl-username"
codex
```

### OpenCode

Add to `~/.config/opencode/opencode.json`:

```json
{
  "provider": {
    "argo-proxy": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Argo Proxy",
      "options": {
        "baseURL": "http://localhost:44497/v1",
        "apiKey": "your-anl-username"
      },
      "models": {
        "argo:gpt-5": { "name": "GPT-5" },
        "argo:claude-4.5-sonnet": { "name": "Claude 4.5 Sonnet" },
        "argo:gemini-2.5-pro": { "name": "Gemini 2.5 Pro" }
      }
    }
  }
}
```

List available models:

```bash
argo-proxy models
```

Do not hard-code the catalog — model names and availability change. Use the command above or `GET http://localhost:44497/v1/models` to fetch the current list.

### Cursor

Cursor sends requests for custom models from its own servers, not from your machine, so it cannot reach an
argo-proxy on `localhost` or on the ANL network. Use one of the other tools with argo-proxy.

### Kilo Code

In Kilo Code VS Code extension settings:

- **Base URL**: `http://localhost:44497`
- **API Key**: `your-anl-username`

Kilo Code connects via the Anthropic Messages API (`/v1/messages`), so the base URL is the proxy root (no `/v1` suffix).

---

## argo-shim

A lightweight HTTP proxy + SSH tunnel for Claude Code and Codex CLI on ALCF machines. Bridges plain HTTP (what the tools speak) to HTTPS (what the tunnel carries).

!!! warning "SSH setup is mandatory"
    argo-shim tunnels to CELS via SSH. CELS/CSPO security monitors failed logins and will block a whole node's IP after repeated failures, which breaks Argo for everyone on that node. **Do not restart argo-shim if SSH fails — fix your SSH key first.**

### Prerequisites

1. **SSH key to CELS** (one time):

   ```bash
   ssh-keygen -t ed25519
   cat ~/.ssh/id_ed25519.pub
   ```

   Paste the public key (`.pub` file) into [https://accounts.cels.anl.gov](https://accounts.cels.anl.gov), **not** your private key.

2. **Load the key into your SSH agent:**

   ```bash
   ssh-add
   ```

3. **Verify SSH works** (before running argo-shim):

   ```bash
   ssh -o BatchMode=yes -J logins.cels.anl.gov homes.cels.anl.gov true
   ```

   If this succeeds silently (exit 0, no password), you're ready. If it fails, fix it here — argo-shim cannot work until this does.

### Install and run

```bash
uvx argo-shim              # run directly, no install
# OR
pip install argo-shim
argo-shim
```

The shim creates an SSH tunnel, starts a local HTTP proxy, and writes config to `~/.claude/settings.json`. Port is derived from your username (deterministic across restarts).

### Claude Code

```bash
argo-shim
# In another terminal:
claude
```

argo-shim writes `ANTHROPIC_BASE_URL` and `apiKeyHelper` to `~/.claude/settings.json`. No manual config needed.

### Codex CLI

```bash
argo-shim --codex
codex --profile argo
```

The `--codex` flag writes a managed provider to `~/.codex/config.toml` and a profile to `~/.codex/argo.config.toml`. Re-run `argo-shim --codex` after port changes or to refresh the token.

!!! note "Codex and the Responses API"
    Current Codex speaks only the Responses API. Argo serves it natively, and argo-shim routes Codex to it, so
    any recent Codex works.

### Running from compute nodes

Compute nodes have no outbound network access. Create the tunnel on a UAN instead:

**On UAN:**

```bash
argo-shim --tunnel
```

Prints the command to run on the compute node.

**On compute node:**

```bash
argo-shim --tunnel-host <uan-hostname>
no_proxy=localhost,127.0.0.1 NO_PROXY=localhost,127.0.0.1 claude
```

For details, see [argo-shim: Running from Compute Nodes](https://github.com/n-getty/argo-shim#running-from-compute-nodes).

### Already running?

Re-running `argo-shim` is safe. If a healthy shim already exists, it re-syncs settings and exits without touching SSH:

```bash
argo-shim --restart     # clean restart (reuses healthy tunnel)
argo-shim --status      # show lockout/cooldown state
argo-shim --reset       # clear lockout after fixing SSH auth
```

---

## ALCF Inference Endpoints

Public open-weight models on Argonne hardware (Sophia, Metis, Minerva). Authenticate with Globus (any supported DOE lab identity).

### Quick start

Install authentication tools:

```bash
uv tool install alcf-ai alcf-tokens
```

Or `pip install alcf-ai alcf-tokens`.

Login and auto-configure your agent:

```bash
alcf-tokens login inference
alcf-ai agent configure opencode    # or: codex, claude
```

Then run your agent:

```bash
opencode    # or: codex, claude
```

`alcf-ai agent configure` refreshes tokens itself when `alcf-tokens` is on your `PATH`. For a manual
configuration (below), put a fresh token in the environment first:

```bash
export ALCF_AI_TOKEN="$(alcf-tokens get-token inference)"
```

!!! tip "Refreshing tokens"
    Tokens last 48 hours and auto-refresh. Re-authenticate every 30 days: `alcf-tokens login inference` or `alcf-tokens login` for all services.

### Clusters and base URLs

Three active clusters. Pick based on your agent and model needs:

| Cluster | Base URL | API formats | Use case |
|---|---|---|---|
| **Sophia** | `https://inference-api.alcf.anl.gov/resource_server/sophia/vllm/v1` | Chat Completions, Responses, Anthropic Messages, Embeddings | Most open models; chat and coding agents |
| **Metis** | `https://inference-api.alcf.anl.gov/resource_server/metis/api/v1` | Chat Completions, Responses | SambaNova hardware; tool-calling has known issues |
| **Minerva** | `https://inference-api.alcf.anl.gov/resource_server/minerva/api/v1` | Chat Completions, Responses, Anthropic Messages | Direct API endpoint; ALCF's choice for Claude Code and Codex (`inkling-bf16`, `nemotron-3-ultra`) |

See [Available Models](https://docs.alcf.anl.gov/services/inference-endpoints/models/) for the current model list per cluster. Do not hard-code model names — fetch from `/models` or use `alcf-ai ls-models <cluster>`.

### Manual config: OpenCode

Add to `~/.config/opencode/opencode.json`:

```json
{
  "provider": {
    "alcf-sophia": {
      "name": "ALCF Inference (Sophia)",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "https://inference-api.alcf.anl.gov/resource_server/sophia/vllm/v1",
        "apiKey": "{env:ALCF_AI_TOKEN}"
      },
      "models": {
        "openai/gpt-oss-120b": { "name": "GPT-OSS 120B" },
        "meta-llama/Meta-Llama-3.1-70B-Instruct": { "name": "Llama 3.1 70B" }
      }
    }
  }
}
```

Before running OpenCode, export your token:

```bash
export ALCF_AI_TOKEN="$(alcf-tokens get-token inference)"
opencode
```

### Manual config: Codex

Add to `~/.codex/config.toml`:

```toml
model = "inkling-bf16"
model_provider = "alcf-minerva"

[model_providers.alcf-minerva]
name = "ALCF Inference (Minerva)"
base_url = "https://inference-api.alcf.anl.gov/resource_server/minerva/api/v1"
env_key = "ALCF_AI_TOKEN"
wire_api = "responses"
```

Codex also needs a model catalog entry for a model it does not know. ALCF's
[Codex instructions](https://docs.alcf.anl.gov/services/inference-endpoints/agents/#codex) include a script that
writes one (`model_catalog_json`) and the profile that uses it; `alcf-ai agent configure codex` does all of
this for you. Then:

```bash
export ALCF_AI_TOKEN="$(alcf-tokens get-token inference)"
codex
```

!!! warning "Codex needs the Responses API"
    Codex 0.95 and later speak only the Responses API, and Sophia does not stream it, so point Codex at
    Minerva. ALCF's docs give Codex 0.94 or older (Chat Completions) as the alternative for Sophia.

### Manual config: Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://inference-api.alcf.anl.gov/resource_server/minerva/api/v1",
    "ANTHROPIC_AUTH_TOKEN": "<your-alcf-token>",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "inkling-bf16",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "inkling-bf16",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "inkling-bf16"
  }
}
```

Or use `alcf-tokens` to keep tokens fresh:

```bash
alcf-ai agent configure claude
```

!!! note "Use Minerva for Claude Code"
    Claude Code needs the Anthropic Messages API (`/v1/messages`). Sophia lists that route too, but ALCF's
    docs say Claude Code works without a shim only on a Direct API endpoint such as Minerva.

### Manual config: Cursor

In Cursor settings:

- **Base URL**: `https://inference-api.alcf.anl.gov/resource_server/sophia/vllm/v1` (Chat Completions)
- **API Key**: paste the output of `alcf-tokens get-token inference` (the field does not run commands)

The token expires after 48 hours and Cursor does not refresh it, so paste a new one when requests start
failing. Not tested.

### Manual config: Kilo Code

In Kilo Code VS Code settings:

- **Base URL**: `https://inference-api.alcf.anl.gov/resource_server/minerva/api/v1`
- **API Key**: Token from `alcf-tokens get-token inference`

The token expires after 48 hours; paste a new one when requests start failing. Not tested.

### Limitations and workarounds

- **Tool calling broken on Metis**: SambaNova's tool-call sanitization has a known issue. Use Sophia or Minerva for tool calling.
- **Streaming off for Responses on Sophia**: Codex on Sophia cannot stream with the Responses API. Use Chat Completions or switch to Minerva.
- **Connection timeout**: the model may still be loading. Check what is running with `alcf-ai ls-jobs <cluster>`.
- **Permission denied after 30 days**: Re-authenticate: `alcf-tokens login inference` or `alcf-tokens clear-tokens` then `alcf-tokens login`.

See [ALCF Inference Troubleshooting](https://docs.alcf.anl.gov/services/inference-endpoints/#troubleshooting) for more.

---

## i2-core

AmSC Intelligent Interfaces (i2) commercial API. Access a curated set of models (e.g., `grok-4.6`) via an OpenAI-compatible endpoint.

!!! warning "Experimental service — read the ToS"
    i2-core is experimental and subject to change. Service availability is best-effort only. **Do not** transmit PII, confidential, or export-controlled data. **Do not** connect to public-facing chatbots. Store your key securely (env vars, secrets manager) and **immediately disable it if leaked**. Support: [andrew.schmeder@americansciencecloud.org](mailto:andrew.schmeder@americansciencecloud.org).

### Get a key

Visit the [i2-core API key manager](https://api.i2-core.american-science-cloud.org/) and request an API key. Store it securely:

```bash
export I2CORE_API_KEY="sk-xxxxxxxxxx"
```

Never commit or publish the key.

### Test the API

List available models:

```bash
curl -X 'GET' \
    'https://api.i2-core.american-science-cloud.org/models' \
  -H "Authorization: Bearer ${I2CORE_API_KEY}" \
  -H 'accept: application/json'
```

Chat completions (example):

```bash
curl -X 'POST' \
  'https://api.i2-core.american-science-cloud.org/v1/chat/completions' \
  -H "Authorization: Bearer ${I2CORE_API_KEY}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "model": "grok-4.6",
  "messages": [
    {
      "role": "user",
      "content": "Hello, how are you?"
    }
  ]}'
```

### OpenCode

Add to `~/.config/opencode/opencode.json`:

```json
{
  "provider": {
    "i2-core": {
      "name": "i2-core (AmSC)",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "https://api.i2-core.american-science-cloud.org/v1",
        "apiKey": "{env:I2CORE_API_KEY}"
      },
      "models": {
        "grok-4.6": { "name": "Grok 4.6" }
      }
    }
  }
}
```

Before running OpenCode, export your key:

```bash
export I2CORE_API_KEY="sk-xxxxxxxxxx"
opencode
```

List all available models and add them to the `models` object above — fetch from the API with the curl command above instead of hard-coding.

---

## In the container

The tutorial `run.sh` and `run.ps1` (and the dev container) pass these from your host when they are set:
`ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `OPENAI_API_KEY`, `OPENAI_BASE_URL`,
`OPENROUTER_API_KEY`, `ALCF_AI_TOKEN` and `I2CORE_API_KEY`. Set the keys on the host, then start the
container:

```bash
export ALCF_AI_TOKEN="$(alcf-tokens get-token inference)"   # ALCF Inference (expires after 48 hours)
export I2CORE_API_KEY="sk-xxxxxxxxxx"                         # i2-core
/path/to/run.sh
```

**OpenCode provider config.** Your host's `~/.config/opencode` is not visible in the container. Either put
the `provider` block in an `opencode.json` at the root of your project (it is mounted, and the
`{env:...}` keys keep secrets out of the file), or create `~/.config/opencode/opencode.json` once inside the
container; that folder is a named volume, so it is kept across runs.

**argo-proxy on the host.** Inside the container, `localhost` is the container itself. With Docker Desktop
(macOS, Windows), use `http://host.docker.internal:44497` wherever this page says `http://localhost:44497`.

---

## Choosing a backend

| Scenario | Backend | Why |
|---|---|---|
| **Inside ANL, want all tools** | argo-proxy | Single gateway, all APIs, lowest latency |
| **On ALCF machine, Claude Code or Codex** | argo-shim | No local proxy needed; SSH tunnel handles auth |
| **Public/multi-institutional, open models** | ALCF Inference | Globus auth, official ALCF support, web UI included |
| **Genesis Mission, any tool** | MAG or argo-proxy | MAG has direct docs; argo-proxy as fallback |
| **AmSC commercial models, OpenCode** | i2-core | Curated commercial models via OpenAI-compatible API |
