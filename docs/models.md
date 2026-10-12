# Models and budget

For Argonne-hosted backends (argo-proxy, argo-shim, ALCF Inference Endpoints), see [Custom endpoints](endpoints.md).

## Where to look, and how to read a score

| Benchmark | What it measures | Who runs it | Link |
|---|---|---|---|
| SWE-bench Pro | real issues in maintained repos; public and private (commercial) sets | Scale, one fixed agent scaffold for every model | [labs.scale.com/leaderboard/swe_bench_pro](https://labs.scale.com/leaderboard/swe_bench_pro) |
| Terminal-Bench | long, multi-step shell tasks, run inside real agents (Claude Code, Codex, …) | Stanford / Laude; harness listed per row | [tbench.ai](https://tbench.ai) |
| SWE-rebench | fresh GitHub issues added every month, so no training-data leakage | Nebius; fixed scaffold, 5 runs per task | [swe-rebench.com](https://swe-rebench.com) |
| SWE-bench-Live | continuously added tasks, many languages | Microsoft and academic partners | [swe-bench-live.github.io](https://swe-bench-live.github.io) |
| Vals.ai | independent re-runs on one harness; reports cost and time per task | Vals AI | [vals.ai/benchmarks](https://vals.ai/benchmarks) |
| Artificial Analysis | independent: runs Terminal-Bench, SciCode and more on every model, with price and cost per task | Artificial Analysis | [artificialanalysis.ai](https://artificialanalysis.ai) |

- **Same harness, same split, or do not compare.** The scaffold and the data split move a score by tens of points.
- **SWE-bench Verified is saturated**: top models score 95–97% and its tasks are in public training data.
- **Your own benchmark** is the one that decides: run the lab on two models and compare tests passed, minutes and dollars.

## The menu, checked 7 Oct 2026

All scores below are from [Artificial Analysis](https://artificialanalysis.ai/leaderboards/models), run on one
harness at each model's best reasoning setting, so you can compare down a column. *$ / task* is the average cost
of one Intelligence Index task at list price. Open-weights models are listed only from US and European developers.

| Tier | Model | Context | $ / M in / out | $ / task | AA Index | T-Bench 4.0 | SciCode |
|---|---|---|---|---|---|---|---|
| Premium: rare hard problems | Claude Fable 5.1 | 1M | 10 / 50 | 7.63 | 53.4 | 52% | 63% |
|  | GPT-6 Astra | 1M | 10 / 50 * | 3.26 | 52.7 | 59% | 56% |
| Frontier: planning, algorithms | Claude Opus 5.5 | 1M | 4 / 20 | 5.98 | 57.6 | 60% | 67% |
| Mid: edits, tests, GUI | Claude Sonnet 5.5 | 1M | 2 / 10 | 7.67 | 56.0 | 64% | 61% |
|  | Gemini 4 Argon | 1M | 2 / 10 | 1.99 | 52.6 | 57% | 62% |
|  | GPT-6.1 Sol | 1M | 2 / 10 * | 0.72 | 51.8 | 56% | 54% |
| Fast: sub-agents, search | Gemini 3.8 Flash | 1M | 0.75 / 3.75 † | 1.24 | 40.9 | 20% | 57% |
|  | GPT-6 Luna | 1M | 0.1 / 0.5 * | 0.07 | 38.1 | 13% | 55% |
|  | Claude Haiku 4.5 | 200K | 1 / 5 | 0.28 | 16.9 | 0% | 42% |
| Open weights (US / EU) | Nemotron 3 Ultra (NVIDIA) | 262K | 0.6 / 2.5 | 0.60 | 22.9 | <1% | 40% |
|  | Muse Glimmer (Meta) | 131K | 0.325 / 1.35 | 0.06 | 17.5 | <1% | 45% |
|  | Gemma 4 31B (Google) | 256K | 0.165 / 0.4 ‡ | ~0 | 14.7 | 0% | 45% |
|  | Mistral Medium 3.5 (Mistral, FR) | 256K | 1.5 / 7.5 | 0.50 | 14.2 | 0% | 40% |
|  | gpt-oss-120b (OpenAI) | 131K | 0.15 / 0.595 | 0.11 | 11.6 | 0% | 34% |

\* OpenAI charges more above ~272K tokens. † Introductory price to 31 Dec. ‡ Cheapest paid hosted listing; free
tiers exist, or self-host. **These numbers change monthly.**

Price per token is not cost per task: two models with the same token price can differ tenfold per task.

## Budgeting

- **Output costs about 5× input**; cached input costs much less; batch jobs are about half price.
- **Every turn re-sends the context**, so a long session costs more per turn as it grows. `/clear` between tasks
  saves money as well as quality.
- **Stable prefixes get cached**: a short, fixed instructions file is cheap.
- **Sticker prices are not comparable** across providers: tokenizers differ by about 30% for the same text.
- **A subscription is not an API key**: plans meter usage windows with a weekly cap; API keys bill per token.

| Tool | During a session | History and caps |
|---|---|---|
| Claude Code | /usage (= /cost, /stats) · /context | Console spend limits · claude -p --max-budget-usd 5 --max-turns 5 |
| Codex | /status: limits and context left · /usage: tokens | usage dashboard; no per-session dollars |
| OpenCode | tokens and cost in the session view | your provider's console |
| Any of them |  | npx ccusage@latest daily — reads local session logs, prices at list rates |

Cheapest habits: `/clear` between tasks, a smaller model for sub-agents, lower reasoning effort for easy edits,
and disconnect MCP servers you are not using.
