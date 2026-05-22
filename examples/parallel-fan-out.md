# Parallel fan-out — worked example

> Domain-agnostic illustration of METHOD.md §6 (multi-agent orchestration) using the concrete parallel-browser-harness recipe from `docs/parallel-agents.md`. Based on a real 3-agent research run; project specifics removed.

---

## The question

A team needed to understand how a widely-used CAD/DXF format handles drawing-type classification — specifically: what deterministic signals exist to recognize whether a given file is a floor plan, an elevation, a section, etc., without using ML. The question split naturally into three independent angles with different source sets.

---

## Pre-research plan (METHOD.md §1.5)

```
ANGLE DECOMPOSITION:
  A — Standards angle: what do official CAD standards (AIA/NCS layer naming) say about encoding drawing type into layer names and title blocks?
  B — Practitioner/ML angle: what does the academic literature on automated drawing classification show about signal reliability and failure modes?
  C — Tooling angle: what APIs does the de facto open-source DXF parser expose for extracting the signals identified in A and B?

PARALLELIZATION: Fan out (all three angles are independent; no angle's answer is required before another can begin).
COUNCIL PLAN: After findings merge, orchestrator synthesizes a ranked signal stack and confidence assessments. Council only if synthesis reveals a genuine contradiction that affects the architecture decision.
```

---

## Setup: launch three Chrome instances (orchestrator, before briefing subagents)

```bash
BH_PORT=9223 ./scripts/browser-harness-headless.sh start  # angle A
BH_PORT=9224 ./scripts/browser-harness-headless.sh start  # angle B
BH_PORT=9225 ./scripts/browser-harness-headless.sh start  # angle C
```

Output from each:
```
headless Chrome up on port 9223 (profile: ~/.cache/bh-chrome-profile-9223)
export BU_CDP_URL=http://127.0.0.1:9223
```

---

## Subagent briefs (one per angle)

### Agent A brief (standards)

```
TASK:           What drawing-type signals are defined in official CAD layer standards (AIA/NCS)? Specifically: are there explicit field codes for floor plan, elevation, section, site plan, detail, schedule? Which drawing types have explicit codes and which do not?
YOUR SCOPE:     Official standards only (AIA CAD Layer Guidelines, US National CAD Standard). Do not cover ML classification or parser APIs.
AUTH SOURCES:   nationalcadstandard.org, AIA CAD Layer Guidelines PDFs, practitioner references that cite the primary standard.
SEARCH LADDER:  Run authority-direct, filetype hunt, practitioner forum, primary docs, contrarian, synonym-expansion. (§2)
BROWSER PORT:   9223. Export BU_CDP_URL=http://127.0.0.1:9223, BU_NAME=agent-a.
TOOLING NOTE:   js("document.body.innerText.slice(0,6000)") for text extraction. restart_daemon() first, navigate second.
OUTPUT:         FINDING template entries (templates/finding.md). One entry per claim.
CITATION RULE:  Every claim has a URL + page location. No URL = omit.
BIAS GUARD:     Surface limits and exceptions to the standard FIRST.
STOP CRITERION: Have answered which types have explicit codes and which rely on entity content. Time-box: 12 tool calls.
TIME-BOX:       12 tool calls
CLEANUP:        BH_PORT=9223 ./scripts/browser-harness-headless.sh clean after writing findings.
```

### Agent B brief (academic / practitioner reliability)

```
TASK:           What does the published literature say about how reliable layer names are as a signal for drawing-type classification? What alternative signals (entity content, geometry, title-block OCR) appear in the literature?
YOUR SCOPE:     Academic papers and practitioner literature on automated drawing classification. Do not cover official standards or parser APIs.
AUTH SOURCES:   Springer/Elsevier AEC journals, arXiv, Google Scholar. Target papers on floor-plan parsing, drawing classification, AEC document intelligence.
SEARCH LADDER:  Run authority-direct, filetype hunt, practitioner forum, primary docs, contrarian, synonym-expansion. (§2)
BROWSER PORT:   9224. Export BU_CDP_URL=http://127.0.0.1:9224, BU_NAME=agent-b.
TOOLING NOTE:   js("document.body.innerText.slice(0,6000)"). restart_daemon() first, navigate second.
OUTPUT:         FINDING template entries. One entry per claim.
CITATION RULE:  Every claim has a URL + page location. No URL = omit.
BIAS GUARD:     Surface findings that CONTRADICT the assumption that layer names are reliable.
STOP CRITERION: 2+ independent peer-reviewed sources on signal reliability. Time-box: 12 tool calls.
TIME-BOX:       12 tool calls
CLEANUP:        BH_PORT=9224 ./scripts/browser-harness-headless.sh clean after writing findings.
```

### Agent C brief (parser API)

```
TASK:           What APIs does ezdxf (the primary open-source DXF parser) expose for extracting entity types, layer names, text content, header variables, and space (model vs paper) from a DXF file? Are there built-in tools for entity grouping or classification?
YOUR SCOPE:     ezdxf only. No standards, no ML papers.
AUTH SOURCES:   ezdxf.readthedocs.io, github.com/mozman/ezdxf (tests/ and examples/).
SEARCH LADDER:  Authority-direct first (docs + repo structure). No external search needed if docs answer the question.
BROWSER PORT:   9225. Export BU_CDP_URL=http://127.0.0.1:9225, BU_NAME=agent-c.
TOOLING NOTE:   js("document.body.innerText.slice(0,6000)"). restart_daemon() first, navigate second.
OUTPUT:         FINDING template entries with code examples from official docs or tests/examples/.
CITATION RULE:  URL + section or file path for every claim.
BIAS GUARD:     Surface limitations and missing built-ins explicitly (e.g. no built-in drawing-type classifier).
STOP CRITERION: Have listed all relevant APIs. Time-box: 10 tool calls.
TIME-BOX:       10 tool calls
CLEANUP:        BH_PORT=9225 ./scripts/browser-harness-headless.sh clean after writing findings.
```

---

## Agents run in parallel, each writes to its own file

```
findings/angle-a-standards.md       ← agent A writes here
findings/angle-b-literature.md      ← agent B writes here
findings/angle-c-parser-api.md      ← agent C writes here
```

Each agent returns a one-line pointer to the orchestrator:
- `angle-a-standards.md: complete. 6 FINDINGs. 1 gap (NCS V6 PDF not rendered).`
- `angle-b-literature.md: complete. 4 FINDINGs. Key result: layer names unreliable (peer-reviewed).`
- `angle-c-parser-api.md: complete. 5 FINDINGs. All target APIs confirmed. No built-in type classifier.`

The orchestrator does NOT receive the bodies. It reads the files directly.

---

## Merge (METHOD.md §6)

After all three return, the orchestrator:

1. Collects all FINDINGs across the three files.
2. Finds CONTRADICTS pairs: none in this run (the three angles were genuinely independent).
3. Lists gaps no agent covered: quantitative AIA compliance rate in real-world files (not in any angle's scope — flag for follow-up, not a blocker).
4. Synthesizes a ranked signal table tracing each row to specific FINDING IDs:

| Signal | Confidence | Source |
|---|---|---|
| Paperspace title-block keyword (FLOOR PLAN / ELEVATION / …) | MED (~70% of professional sets) | A-01 (standards), B-03 (lit: title block OCR reliable) |
| AIA layer drawing-view codes (-ELEV, -SECT, -DETL) | HIGH when present, AIA-compliant files only | A-01, A-02 |
| Floor-plan entity cluster (wall + door + window + room labels + closed polylines) | HIGH — survives non-conformant layer names | B-01, B-02, C-02 |
| Section hatch signal (HATCH on cut/boundary layers) | MED | A-03, C-03 |
| DIMENSION orientation histogram | LOW (unverified threshold) | B-04 |
| Per-layer geometric content (entity-type histogram) | HIGH in literature, no OSS implementation found | B-02, gap |

5. Every prose claim in the synthesis traces to a FINDING ID. No unsourced assertions.

---

## Result

Three parallel agents each owned an isolated Chrome instance (ports 9223–9225, separate profile directories). Each wrote its own FINDING file. The orchestrator merged via the table above. The synthesis identified the ranked signal stack and clearly separated what is standards-defined, what is literature-validated, and what remains a gap.

Cleanup was per-agent and per-profile: no other Chrome instances were affected. The raw page cache was removed. Only the three FINDING files and this synthesis remain on disk.

---

## Why this pattern over a single serial agent

A single serial agent running all three angles would spend ~3× the tool calls before producing a synthesis, accumulate context from unrelated source domains into one context window, and have no natural isolation between the standards reading and the paper reading. The parallel run kept each context narrow and fast, with zero coordination overhead between agents (they were genuinely independent). The only coordination was at the merge step, which is where coordination belongs.
