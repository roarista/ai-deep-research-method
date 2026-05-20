# Deep Research Method for AI Agents

A battle-tested method for getting **human-quality research out of AI agents** — and a small runnable toolkit to execute it.

The problem this solves: naive AI research runs one generic query, reads SEO-blog snippets, and misses what a human finds in seconds. This method fixes that with **scoped pre-research, an authority-chain search ladder, citation-enforced findings, parallel subagents, and a multi-model "council" that synthesizes by debate** — all of which run on free/local tooling.

> Origin: extracted from a real project where research quality *was* product quality. The included worked example (`examples/`) is the first run under this method — it overturned three assumptions the project had been building on.

## The method in one screen

1. **Classify the question** into a tier (LIGHTWEIGHT / STANDARD / FULL) by how many independent sub-questions it has.
2. **Scope it** — fill a one-page contract before searching (`templates/scoping-contract.md`).
3. **Plan the research** (FULL only) — name the exact sources and queries per sub-question *before* any agent runs (`templates/pre-research-plan.md`). This is the highest-leverage step.
4. **Fan out** parallel subagents, each briefed with a tight scope + citation rule (`templates/subagent-brief.md`).
5. **Record every claim** in a fixed FINDING shape — no URL, no finding (`templates/finding.md`).
6. **Convene a council** (FULL only) — three independent models read the same findings and argue to the decision (`templates/council-brief.md`).

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
- **Council (optional but recommended for FULL):** three independent model CLIs so failure modes don't correlate. The reference set is:
  - **Claude** — [Claude Code](https://claude.com/claude-code) (`claude`)
  - **Codex** — OpenAI Codex CLI (`codex`)
  - **Kimi** — Moonshot Kimi CLI (`kimi`)
  - Any three distinct models work. Edit `scripts/run-council.sh` to match the CLIs you have.

## Quick start

```bash
# 1. Read the method
less METHOD.md

# 2. For a real research question, copy the templates and fill them in
cp templates/scoping-contract.md   my-research/contract.md
cp templates/pre-research-plan.md  my-research/plan.md

# 3. (FULL tier) launch headless depth-browsing
./scripts/browser-harness-headless.sh start

# 4. ...run your agents, collect FINDINGs into one doc...

# 5. (FULL tier) convene the council on the merged findings
./scripts/run-council.sh my-research/findings.md my-research/council-brief.md
```

## License

MIT — see [`LICENSE`](LICENSE).
