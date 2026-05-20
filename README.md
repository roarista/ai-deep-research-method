# Deep Research Method for AI Agents

A battle-tested method for getting **human-quality research out of AI agents** — and a small runnable toolkit to execute it.

The problem this solves: naive AI research runs one generic query, reads SEO-blog snippets, and misses what a human finds in seconds. This method fixes that with **scoped pre-research, an authority-chain search ladder, citation-enforced findings, parallel subagents, and a multi-model "council" that synthesizes by debate** — all of which run on free/local tooling.

> Origin: extracted from a real project where research quality *was* product quality. The included worked example (`examples/`) is the first run under this method — it overturned three assumptions the project had been building on.

## The method in one screen

Two tiers, picked up front. **LIGHT** = a single re-checkable fact: one agent, one-line answer + URL, done. **HEAVY** = anything that shapes a decision or splits into several angles — run the full pipeline:

1. **Scope it** — fill a one-page contract before searching (`templates/scoping-contract.md`).
2. **Brainstorm the research itself** (the highest-leverage step) — decide the sources and queries, split the question into distinct angles/perspectives, and write the exact harness each agent gets, *before* any agent runs (`templates/pre-research-plan.md`).
3. **Dispatch** parallel subagents, each on a **different part + different perspective**, briefed with a tight scope + citation rule (`templates/subagent-brief.md`).
4. **Record every claim** in a fixed FINDING shape — no URL, no finding (`templates/finding.md`).
5. **Convene a council** — three independent models read the same findings and argue to the decision; agreement is signal, disagreement localizes the weak evidence (`templates/council-brief.md`).

Full playbook: **[`METHOD.md`](METHOD.md)**.

## What's runnable here (the toolkit)

| Script | What it does |
|---|---|
| `scripts/browser-harness-headless.sh` | Launches an isolated headless Chrome for depth-research (read JS-rendered pages, follow links, browse repo trees) without touching your real browser. |
| `scripts/run-council.sh` | Sends one merged findings doc + a council brief to three CLIs (Claude / Codex / Kimi) independently and collects their verdicts. |

These assume you have the relevant CLIs installed (see **Requirements**). They are deliberately thin — the value is the *method*; the scripts just remove the boring wiring.

## Requirements

- **Breadth search:** any agent with a web-search tool (the method is tool-agnostic; built-in `WebSearch` works).
- **Depth browsing:** [`browser-harness`](https://github.com/browser-use/browser-harness) + Google Chrome, for reading JS-rendered pages and navigating doc/repo trees structurally. Read-only.
- **Council (recommended for HEAVY):** three *independent* model CLIs so their failure modes don't correlate. The method is model-agnostic — what matters is that the three models are genuinely different, not which vendors. The reference set this was built with:
  - **Claude** — [Claude Code](https://claude.com/claude-code) (`claude`)
  - **Codex** — [OpenAI Codex CLI](https://github.com/openai/codex) (`codex`)
  - **Kimi** — [Moonshot Kimi CLI](https://github.com/MoonshotAI/kimi-cli) (`kimi`)
  - **Swap freely.** Any terminal-driveable model works as a council member — e.g. [Gemini CLI](https://github.com/google-gemini/gemini-cli) (`gemini`), or [OpenRouter](https://openrouter.ai) to reach almost any model (GPT, Llama, DeepSeek, Qwen, Mistral…) through one endpoint. Edit `scripts/run-council.sh` to match the CLIs you have; the only rule is **three distinct models, briefed independently**.

## Quick start

```bash
# 1. Read the method
less METHOD.md

# 2. For a real research question, copy the templates and fill them in
cp templates/scoping-contract.md   my-research/contract.md
cp templates/pre-research-plan.md  my-research/plan.md

# 3. (HEAVY tier) launch headless depth-browsing
./scripts/browser-harness-headless.sh start

# 4. ...run your agents, collect FINDINGs into one doc...

# 5. (HEAVY tier) convene the council on the merged findings
./scripts/run-council.sh my-research/findings.md my-research/council-brief.md
```

## Credits & acknowledgements

This method stands on tools and prior work by others. Credit where it's due:

**Tools the toolkit drives**
- [browser-harness](https://github.com/browser-use/browser-harness) by [Browser Use](https://browser-use.com) — the headless-Chrome depth-browsing layer that lets an agent read JS-rendered pages and navigate repo/doc trees. This is what closed the "agents browse worse than humans" gap.
- [Claude Code](https://claude.com/claude-code) (Anthropic) — reference orchestrator and a council member.
- [OpenAI Codex CLI](https://github.com/openai/codex) (OpenAI) — council member.
- [Moonshot Kimi CLI](https://github.com/MoonshotAI/kimi-cli) (Moonshot AI) — council member.
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) (Google) and [OpenRouter](https://openrouter.ai) — alternative / additional council members.

None of these projects endorse this repo; the integration scripts are thin wrappers and all trademarks belong to their owners.

**Ideas the method is built on** (see full list in [`METHOD.md`](METHOD.md#sources))
- Anthropic Engineering — *How We Built Our Multi-Agent Research System* (the fan-out / orchestrator pattern).
- *Deep Research Agents: A Systematic Examination and Roadmap* (arXiv 2506.18096) and *Deep Research: A Survey of Autonomous Research Agents* (arXiv 2508.12752).
- OSINT investigation practice and structured-analytic-technique literature (authority chains, triangulation, source tiering).

## License

MIT — see [`LICENSE`](LICENSE).
