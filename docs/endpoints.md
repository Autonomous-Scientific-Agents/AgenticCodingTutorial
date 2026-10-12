# Custom LLM endpoints

Point your coding agent at Argonne-hosted backends: argo-proxy (ANL), argo-shim (ALCF compute), ALCF Inference Endpoints (open-weight models), or i2-core (AmSC commercial models).

| Backend | Network | Auth | Five tools | Official docs |
|---|---|---|---|---|
| **argo-proxy** | ANL internal / VPN | ANL username | All five | [argo-proxy ReadTheDocs](https://argo-proxy.readthedocs.io) |
| **argo-shim** | ALCF machine (UAN/login) | CELS SSH key | Claude Code, Codex CLI | [argo-shim README](https://github.com/n-getty/argo-shim) |
| **ALCF Inference** | Public (Globus auth) | Globus token | All five | [ALCF Inference Endpoints](https://docs.alcf.anl.gov/services/inference-endpoints) |
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

Default port: `44497`. Check `~/.config/argoproxy/config.yaml` or startup output for your host and port.

### Claude Code

```bash
claude config set -g apiKeyHelper "echo 'your-anl-username'"
claude config set -g env.ANTHROPIC_BASE_URL "http://localhost:44497"
claude config set -g env.CLAUDE_CODE_SKIP_ANTHROPIC_AUTH "1"
claude
```

The `CLAUDE_CODE_SKIP_ANTHROPIC_AUTH=1` flag is required — it skips Anthropic's default auth flow.

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

In Cursor settings (or `.cursor/settings.json`):

- **Base URL**: `http://localhost:44497/v1`
- **API Key**: `your-anl-username`

Use the same chat completions endpoint as OpenCode.

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

!!! note "Codex version"
    Codex ≥ 0.95 dropped Chat Completions support. Use ≤ 0.94 or stick to the Responses API. argo-shim supports both with automatic routing.

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
opencode
# OR
alcf-tokens get-token inference | tee ~/.alcf_token
export ALCF_AI_TOKEN="$(cat ~/.alcf_token)"
codex --profile alcf  # if you ran alcf-ai with --codex
```

!!! tip "Refreshing tokens"
    Tokens last 48 hours and auto-refresh. Re-authenticate every 30 days: `alcf-tokens login inference` or `alcf-tokens login` for all services.

### Clusters and base URLs

Three active clusters. Pick based on your agent and model needs:

| Cluster | Base URL | API formats | Use case |
|---|---|---|---|
| **Sophia** | `https://inference-api.alcf.anl.gov/resource_server/sophia/vllm/v1` | Chat Completions, Responses, Anthropic Messages, Embeddings | Most open models; chat and coding agents |
| **Metis** | `https://inference-api.alcf.anl.gov/resource_server/metis/api/v1` | Chat Completions, Responses | SambaNova hardware; tool-calling has known issues |
| **Minerva** | `https://inference-api.alcf.anl.gov/resource_server/minerva/api/v1` | Chat Completions, Responses, Anthropic Messages | Optimized for Claude via Anthropic Messages API |

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
model = "openai/gpt-oss-120b"
model_provider = "alcf-minerva"

[model_providers.alcf-minerva]
name = "ALCF Inference (Minerva)"
base_url = "https://inference-api.alcf.anl.gov/resource_server/minerva/api/v1"
env_key = "ALCF_AI_TOKEN"
wire_api = "responses"
```

Export token and run:

```bash
export ALCF_AI_TOKEN="$(alcf-tokens get-token inference)"
codex
```

!!! warning "Codex ≥ 0.95"
    Chat Completions API support was removed in Codex 0.95. Use Codex ≤ 0.94 on Sophia, or use Minerva (Responses API). See [Codex Version Requirement](https://docs.alcf.anl.gov/services/inference-endpoints/agents/#codex).

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

!!! note "Anthropic Messages API required"
    Claude Code needs the Anthropic Messages API (`/v1/messages`). Minerva supports it; Sophia does not. Use Minerva for Claude Code.

### Manual config: Cursor

In Cursor settings:

- **Base URL**: `https://inference-api.alcf.anl.gov/resource_server/sophia/vllm/v1` (Chat Completions)
- **API Key**: `$(alcf-tokens get-token inference)` or paste a token manually

Cursor supports OpenAI-compatible endpoints natively.

### Manual config: Kilo Code

In Kilo Code VS Code settings:

- **Base URL**: `https://inference-api.alcf.anl.gov/resource_server/minerva/api/v1`
- **API Key**: Token from `alcf-tokens get-token inference`

Kilo Code uses the Anthropic Messages API, so point at Minerva (which supports it).

### Limitations and workarounds

- **Tool calling broken on Metis**: SambaNova's tool-call sanitization has a known issue. Use Sophia or Minerva for tool calling.
- **Streaming off for Responses on Sophia**: Codex on Sophia cannot stream with the Responses API. Use Chat Completions or switch to Minerva.
- **Connection timeout**: Model is queued. Check status: `curl -H "Authorization: Bearer ${token}" https://inference-api.alcf.anl.gov/resource_server/docs` (Swagger UI) or use `alcf-ai job status`.
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

The tutorial `run.sh` / `run.ps1` forward authentication env vars from your host:

```bash
ANTHROPIC_BASE_URL=... OPENAI_BASE_URL=... /path/to/run.sh
```

For ALCF Inference, argo-proxy, or i2-core with OpenCode, set on your host:

```bash
export ALCF_AI_TOKEN="$(alcf-tokens get-token inference)"      # ALCF Inference
export I2CORE_API_KEY="sk-xxxxxxxxxx"                           # i2-core
export OPENCODE_CONFIG_DIR="$HOME/.config/opencode"             # optional: sync config
/path/to/run.sh
```

Inside the container, copy your OpenCode config:

```bash
# Host: mount or copy ~/.config/opencode into the container
# In container:
opencode
```

Or configure inside the container once and persist:

```bash
docker volume inspect ai-agents-opencode-config   # see where it lives
# Config is preserved across container runs
```

---

## Choosing a backend

| Scenario | Backend | Why |
|---|---|---|
| **Inside ANL, want all tools** | argo-proxy | Single gateway, all APIs, lowest latency |
| **On ALCF machine, Claude Code or Codex** | argo-shim | No local proxy needed; SSH tunnel handles auth |
| **Public/multi-institutional, open models** | ALCF Inference | Globus auth, official ALCF support, web UI included |
| **Genesis Mission, any tool** | MAG or argo-proxy | MAG has direct docs; argo-proxy as fallback |
| **AmSC commercial models, OpenCode** | i2-core | Curated commercial models via OpenAI-compatible API |
