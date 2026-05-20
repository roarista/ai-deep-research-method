# A.I. Deep Research Method

![A.I. Deep Research Method — a scoped question fans out to parallel research agents, each on a different perspective, then converges on a three-model council that debates to a cited conclusion](assets/hero.png)

A battle-tested method for getting **human-quality research out of AI agents** — and a small runnable toolkit to execute it.

The problem this solves: naive AI research runs one generic query, reads SEO-blog snippets, and misses what a human finds in seconds. This method fixes that with **scoped pre-research, an authority-chain search ladder, citation-enforced findings, parallel subagents, and a multi-model "council" that synthesizes by debate** — all of which run on free/local tooling.

> Origin: extracted from a real project where research quality *was* product quality. The `examples/` directory contains two worked examples: a format-priority HEAVY-tier run that overturned three prior assumptions, and a divergent–convergent case study showing how structural re-description surfaced a route nobody in the conversation had named.

## The method in one screen

Two tiers, picked up front. **LIGHT** = a single re-checkable fact: one agent, one-line answer + URL, done. **HEAVY** = anything that shapes a decision or splits into several angles — run the full pipeline:

1. **Scope it** — fill a one-page contract before searching (`templates/scoping-contract.md`).
2. **Brainstorm the research itself** (the highest-leverage step) — decide the sources and queries, split the question into distinct angles/perspectives, and write the exact harness each agent gets, *before* any agent runs (`templates/pre-research-plan.md`).
3. **Divergent–convergent pass** (optional but high-value for creative/open-ended questions) — a high-temperature divergent agent re-describes artifacts *structurally* to reach analogy bridges across domains, commissions exploratory probes, then a low-temperature convergent agent feasibility-screens the survivors. Both work via **request-and-dispatch**: they emit research requests, the orchestrator spawns clean-context sub-agents, results go to disk, only pointers come back. Depth bound stays at 2 — no recursive spawning (`METHOD.md` §1.6–1.7).
4. **Dispatch** parallel subagents, each on a **different part + different perspective**, briefed with a tight scope + citation rule (`templates/subagent-brief.md`).
5. **Record every claim** in a fixed FINDING shape — no URL, no finding (`templates/finding.md`).
6. **Convene a council** — three independent models read the same findings and argue to the decision; agreement is signal, disagreement localizes the weak evidence (`templates/council-brief.md`).

Full playbook: **[`METHOD.md`](METHOD.md)**.

## Why divergent–convergent — and why it works

The hero image up top is the method in one picture: a question **fans out** (the orange node) into many divergent paths, then those paths **pull back together** (the blue node) into one grounded answer. That two-beat rhythm is the whole engine, and it's borrowed directly from how human creativity works.

Cognitive scientists describe creative thinking as exactly these two complementary modes. **Divergent thinking** generates many possibilities, reaches sideways across domains, and tolerates ideas that don't yet make sense — it's the part of you that says *"wait, this is really just a kind of that."* **Convergent thinking** then judges, screens, and narrows toward the one option that actually holds up. Neither mode alone is creative: divergence without convergence is noise, convergence without divergence is the obvious answer everyone already had. Insight lives in the handoff between them.

This method runs those two modes as **two agents with opposite postures** instead of leaving them tangled in one prompt:

- **A high-temperature divergent agent** does the human leap — it *strips the name and states the structure* ("matplotlib isn't a plotting library, it's a renderer that emits clean 2D line drawings — which is what an architectural sketch is"), then asks *whose problem is this already?* and reaches deliberately into unexpected domains (game engines, CNC toolpaths, medical imaging, manga line-art) to find analogy bridges.
- **A low-temperature convergent agent** does the human discipline — it takes each bridge and asks *does a real tool execute this, does it fit the constraints, does it survive contact with evidence?* — keeping only what's real.

**Why it's so useful:** plain AI research collapses both modes into a single averaged pass, which is why it returns the obvious, the already-indexed, the SEO-blog consensus. Separating them lets the system swing wide *and* land hard — the divergent agent reaches places a keyword search can't (cross-domain analogy, not retrieval), and the convergent agent guarantees those reaches are grounded, not hallucinated. The result is the thing humans are still prized for in research: finding the route nobody in the room had named, then proving it's the right one. The [`examples/`](examples/) directory has a worked case where exactly this surfaced a solution no participant had thought of.

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

# 6. CLEAN UP — purge the browser profile/cache + scratch files (keep only findings)
./scripts/browser-harness-headless.sh clean
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
