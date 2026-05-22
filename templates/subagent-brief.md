# Subagent Brief — <sub-question>

> One per parallel research agent. Briefed identically in structure; scoped narrowly. (METHOD.md §6)

```
TASK:           One precise question, verbatim from the contract / pre-research plan.
YOUR SCOPE:     Exactly which aspect; what is OUT of scope for you.
AUTH SOURCES:   Named tier-1 sources — explore their structure directly (repo /tests/ & /examples/, doc nav), don't keyword-match inside them.
SEARCH LADDER:  Run authority-direct, filetype hunt, practitioner forum, primary docs, contrarian, synonym-expansion. (§2)
BROWSER PORT:   <port> (e.g. 9223). Export BU_CDP_URL=http://127.0.0.1:<port> and BU_NAME=<unique-name> before invoking browser-harness. Do not share a port with another parallel agent. (docs/parallel-agents.md)
TOOLING NOTE:   Extract text with js("document.body.innerText.slice(0,N)") — not capture_screenshot(). Run restart_daemon() in its OWN invocation first, then navigate separately. (docs/parallel-agents.md)
OUTPUT:         The FINDING template, one entry per claim (templates/finding.md).
CITATION RULE:  Every claim has a URL + location within the page. No URL = omit it.
BIAS GUARD:     Treat options equally. Surface evidence AGAINST prior assumptions FIRST.
STOP CRITERION: Success criterion met, OR new-evidence threshold (≥80% overlap with prior results), OR time-box. Hard cap 3 retrieval iterations per sub-q.
TIME-BOX:       <max tool calls>
CLEANUP:        Before returning, delete YOUR disk footprint — fetched pages, screenshots, downloads, scratch/temp files. Keep only the FINDINGs you report. The raw retrieval is reproducible; don't leave it on the drive. Run BH_PORT=<port> ./scripts/browser-harness-headless.sh clean to wipe your browser profile. (§6.6, docs/parallel-agents.md)
```
