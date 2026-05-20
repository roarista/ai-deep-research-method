# Research Method

A method for getting human-quality research out of AI agents. A living standard: every research subagent is briefed with it, and open questions are re-researched through it. The DWG/CAD examples below are from the project this was extracted from — read them as concrete illustrations of the moves, not as the subject.

**Why this exists:** progress is routinely bottlenecked by shallow research. When you're not a domain expert, research quality *is* output quality. The recurring failure: subagents run keyword searches, read snippets, and miss what a human finds in seconds (e.g. real sample files that were "impossible to find" for an agent, trivial for a human). Fixing it took two things — better tooling (headless browsing) and better method. This is the method.

**Tooling stack:** any web-search tool for breadth (get the URLs worth visiting) + headless [`browser-harness`](https://github.com/browser-use/browser-harness) for depth (read JS-rendered pages, follow links, browse repo/doc trees structurally). Read-only. Avoid Playwright MCP for subagents (main-session-only, floods context).

---

## 0. Two tiers — pick before you start

Not every question deserves the full apparatus, and over-formalizing a 30-second lookup is its own anti-pattern. There are exactly two modes. Classify first.

| Tier | When | What runs |
|---|---|---|
| **LIGHT** | A single fact, low stakes, re-checkable in a minute (a version, a license, one API detail). | One agent, ~3-5 tool calls. One-line answer + URL. |
| **HEAVY** | Anything that shapes a decision, locks a choice, feeds a build — or splits into several independent sub-questions. | The full pipeline: **brainstorm → allocate → dispatch → council** (§1.5 → §6 → §6.5). |

**LIGHT** — one line, then go:
```
Q: <precise question>  |  DONE WHEN: <stop criterion>  |  SOURCE: <where the authoritative answer lives>
```
Still obeys the non-negotiables: answer carries a URL+location, mark confidence, flag if unverified.

**HEAVY** — the whole apparatus, in order:
1. **Scope** the question — the research contract (§1).
2. **Brainstorm the research itself** — the pre-research planning stage (§1.5): decide the sources, the queries, and *how to harness each agent* before any of them run. This is the highest-leverage step.
3. **Dispatch** multiple agents in parallel (§6), each pointed at a **different part of the question and a different perspective** — not clones running the same search.
4. **Council** (§6.5): independent models read the same findings and argue to the decision.

**Rule of thumb:** if a wrong answer would cost a wasted build or a bad lock, it's HEAVY. Reversible and re-checkable in a minute, it's LIGHT. When genuinely unsure, go HEAVY — under-scoping is the more expensive error.

---

## 1. Pre-research / scoping (do this BEFORE any query)

The biggest gap between human and naive-agent research: humans scope intuitively; agents don't scope at all. Fill this contract in writing first.

```
RESEARCH CONTRACT
PRECISE QUESTION:      One sentence, answerable by a yes/no, a list, or a specific fact — not "learn about X".
DECISION IT INFORMS:   What we do differently once answered.
GOOD ANSWER LOOKS LIKE: Concrete artifact — a working .dxf URL, a price range with 3 citations, the exact API endpoint + cost.
SUCCESS / STOP CRITERION: Threshold — "3 independent sources agree" / "we have a downloadable test file" / "named the endpoint and its cost".
OUT OF SCOPE:          What to ignore (prevents scope creep).
AUTHORITATIVE SOURCES: The tier-1 sources for THIS domain (e.g. DWG parsing: ezdxf GitHub, ODA docs, Autodesk APS docs, LibreDWG project).
TIME-BOX:              Max tool calls / minutes before returning best-effort with gaps flagged.
```

"Find a free tool that extracts layer names + entity types from a real DWG without ODA, with a working code example" is a scope. "Research DWG parsing" is not.

## 1.5 Pre-research brainstorm (HEAVY tier — the highest-leverage step)

The single biggest lever on research quality is what you decide *before any agent runs*. A naive agent searches for "whatever" in "wherever". The fix is to spend deliberate brainpower up front — a real brainstorming phase — that does three things: **(a)** decide *what* to look for and *where*, **(b)** split the question into distinct angles, and **(c)** write the actual prompt/harness each agent gets so it searches precisely, not vaguely. This stage is where the compute that separates good research from shallow research is spent.

Scale the brainstorm to the question. For a big, council-worthy lock you can even fan out a short cheap **scoping pass** first — one throwaway agent whose only job is to map the source landscape and report back which sites, forums, and repos are worth the real agents' time. Then write the plan:

```
PRE-RESEARCH PLAN
ANGLE DECOMPOSITION:  Split the question into N angles — different PARTS and different PERSPECTIVES
                      (e.g. official-docs angle / practitioner-reality angle / contrarian-limitations angle /
                      cost angle). N drives agent count. Angles should overlap as little as possible.
PER ANGLE, NAME:
  - PERSPECTIVE:    What lens this agent researches from, and why it's distinct from the others.
  - SOURCE MAP:     The specific tier-1 sources for THIS angle (named sites, repos, doc trees, forums) — not "search the web".
  - QUERY SET:      The 5-10 actual query strings, run through the §2 ladder (authority / filetype / forum / contrarian / synonym).
  - GOOD ANSWER:    The concrete artifact that closes it.
  - THE HARNESS:    The exact subagent brief this agent gets (templates/subagent-brief.md) — scope, sources, citation rule, bias guard.
PARALLELIZATION:    Fan out (independent angles) vs. go deep (each query needs the prior answer). See §6.
COUNCIL PLAN:       The exact decision the council (§6.5) must reach once findings land.
```

Rule: **the plan is reviewed before agents launch.** A bad plan multiplied across N parallel agents wastes N× the compute. Cheap to fix on paper, expensive after fan-out.

## 2. Query design / decomposition

Naive agents write one generic query and accept page 1 (SEO blogs, not ground truth). Always run the ladder:

| Level | Type | Example |
|---|---|---|
| 1 | Authoritative source, direct | `site:github.com ezdxf`, `site:docs.autodesk.com dwg` |
| 2 | Filetype hunt | `filetype:dxf floor plan`, `filetype:dwg site:github.com` |
| 3 | Practitioner forum | `site:stackoverflow.com ezdxf DWG layer names` |
| 4 | Primary docs | `"libredwg" API reference` |
| 5 | Negative / contrarian | `"ezdxf" limitations DWG "cannot read"` |
| 6 | Synonym expansion | LLM-generate 10-15 variants (jargon, brands, extensions, versions), re-run 1-5 |

**The key human move agents miss: follow the authority chain, don't keyword-match.** When you find a tier-1 source, *explore its structure directly* (its GitHub `/tests/` and `/examples/` folders, its docs nav) via browser-harness — don't go back to search for content that lives inside it.

## 3. Source selection & triangulation

Source hierarchy (highest weight first):
1. Official docs (README, readthedocs, vendor API docs)
2. Source code itself (tests/examples dirs hold real working artifacts)
3. Papers (arxiv, conference) for technique comparisons
4. Practitioner forums (upvoted/accepted answers)
5. Blogs — only if they cite a primary source
6. AI summaries — zero weight without a citation chain

**Triangulation rule:** no claim becomes a finding without two *independent* sources, or one primary source plus our own test run. Independent = different authors/dates/incentives, not two blogs citing the same whitepaper.

**Staleness:** every versioned/priced/availability claim gets a date check. CAD tooling status (LibreDWG write support, APS pricing, ezdxf DWG support) changes materially within 18 months.

## 4. Extraction & note structure

Every finding in this fixed shape — this is what makes research accumulate instead of evaporate. A finding without a URL is a hallucination risk, not a fact.

```
FINDING
CLAIM:        One precise declarative sentence.
EVIDENCE:     URL + location within page (section/table row/line) — not the homepage.
ACCESS DATE:  YYYY-MM-DD
CONFIDENCE:   HIGH = primary + tested | MED = 2+ secondary agree | LOW = single secondary | UNVERIFIED = one source, untested
CONTRADICTS:  Any conflicting finding, or "none found".
GAPS:         What this does NOT answer that the scope requires.
SOURCE TIER:  1 docs | 2 code | 3 paper | 4 forum | 5 blog
```

## 5. Iteration & stop criteria

Two mirror failures: stopping after the first search (shallow), and looping endlessly (retrieval thrash). After each pass:

1. Did this pass add any finding not already in notes? No → stop.
2. Hit the success criterion? Yes → stop.
3. Exceeded time-box / cap (hard ceiling: 3 retrieval iterations per sub-question)? Yes → return best-effort, gaps flagged.
4. Specific named gap remaining? Design ONE targeted query for exactly it, go to 1.
5. Tempted to widen scope because nothing's found? Stop and escalate — widening is a human decision.

New-evidence threshold: if the latest retrieval is ≥80% overlapping with prior results, treat as empty and stop.

## 6. Multi-agent orchestration

**Fan out** (parallel subagents) when the question splits into independent angles with different source sets — different *parts* of the question and different *perspectives* on it (e.g. an official-docs agent, a practitioner-forum agent, a contrarian-limitations agent, a cost agent). The goal is coverage and viewpoint diversity, not the same search run N times. **Go deep** with one agent instead when each query depends on the prior answer. Premature parallelization orphans findings.

Subagent brief template:
```
SUBAGENT BRIEF
TASK:           One precise question, verbatim from the contract.
YOUR SCOPE:     Exactly which aspect; what is OUT of scope for you.
AUTH SOURCES:   Named tier-1 sources; explore their structure directly.
OUTPUT:         The FINDING template, one entry per claim.
CITATION RULE:  Every claim has a URL + location. No URL = omit it.
BIAS GUARD:     Treat options equally. Surface evidence against prior assumptions FIRST.
TIME-BOX:       Hard cap.
```

Merging: collect all FINDINGs → find CONTRADICTS pairs → resolve by source tier (higher wins; same-tier conflict = flag for human) → list GAPS no one covered (follow-up pass, not final answer) → orchestrator synthesis must trace each prose claim back to specific FINDINGs.

## 6.5 LLM council (HEAVY tier — synthesis by debate, not by merge)

Mechanical merging (above) resolves *factual* conflicts by source tier. It does **not** stress-test the *interpretation* — whether the findings actually support the decision, what a contrarian reads in the same data, what's being over-claimed. For a question that locks a build or an architecture choice, run a council after the parallel research lands.

A council is **three independent models** reading the *same* merged FINDINGs and arguing toward the decision the contract named. Use genuinely different models so the failure modes don't correlate — e.g. **Claude (Opus) + Codex (GPT-5.x) + Kimi (K2)**. Each is briefed identically and independently; no model sees another's answer until all three are in.

```
COUNCIL BRIEF (identical to all three members)
DECISION TO REACH:   The exact call the contract needs (verbatim).
EVIDENCE:            The merged FINDINGs doc — all members read the same one.
YOUR JOB:            Reach the decision FROM the evidence. Cite the specific FINDING behind each claim. No outside facts without a new citation.
ADVERSARIAL DUTY:    State the strongest case AGAINST the majority read. Name what's over-claimed or under-supported.
OUTPUT:              VERDICT + rationale + the findings you relied on + your single biggest doubt.
```

Then the orchestrator (or a human) reads the three verdicts: **agreement across three independent models is a strong signal; disagreement localizes exactly where the evidence is thin** — that becomes the next research gap, not a coin-flip. The council never invents facts; it only reasons over the cited findings. If a member needs a fact that isn't in the findings, that's a GAP for a follow-up pass.

Roles can be assigned (writer / auditor / contrarian) or symmetric (all three reach a verdict, then a fourth pass reconciles). The repo ships both as templates. The council is a HEAVY-tier step only — three model-runs of overhead, wasted on a LIGHT lookup.

## 7. Anti-patterns → countermeasures

| Anti-pattern | Countermeasure |
|---|---|
| Unscoped query | Fill the contract before searching |
| Keyword anchoring | Mandatory synonym expansion |
| Blog-aggregator trap | Enforce source tier; follow citations upstream |
| First-result acceptance | ≥3 sources per MED claim |
| Narrative without citation | FINDING template; no URL = not a finding |
| Retrieval thrash | 3-iteration cap + new-evidence threshold |
| Scope creep | OUT-OF-SCOPE field; escalate changes |
| Source not explored structurally | Navigate the repo/doc tree directly, don't re-search inside it |
| Stale info | Date-check every versioned claim |
| Confident gaps | Mark LOW confidence; record as gap for human verification |

---

## Minimum viable research loop (every subagent, every time)

1. **Fill the scoping contract** — don't search until complete.
2. **Generate query variants** — authority-chain, filetype, synonym, contrarian; batch into 3 angles.
3. **Run queries, then follow authority chains structurally** — navigate tier-1 sources directly via browser-harness.
4. **Record every finding in the FINDING template** — no prose without citations.
5. **Apply stop criteria** — success criterion, new-evidence threshold, time-box.
6. **Flag contradictions and gaps explicitly** — never resolve silently, never omit gaps.
7. **Return structured findings, not a narrative** — orchestrator synthesizes; subagent delivers facts.

---

## Sources
- Deep Research Agents: A Systematic Examination and Roadmap — arxiv 2506.18096
- Deep Research: A Survey of Autonomous Research Agents — arxiv 2508.12752
- Agentic RAG Failure Modes (retrieval thrash, tool storms, context bloat) — Towards Data Science
- OSINT Investigation Workflow — DigitalStakeout
- Sharpen Your OSINT Queries with AI — Flashpoint
- How We Built Our Multi-Agent Research System — Anthropic Engineering
- Ten Steps to Conduct a Systematic Review — NIH/PMC
- Structured Analytic Techniques for Intelligence Analysis — Maltego
