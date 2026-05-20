# Pre-Research Plan — <short title>

> FULL tier only. The highest-leverage step: decide exactly what to look for and where, BEFORE any agent runs. A bad plan multiplied across N parallel agents wastes N× the compute. (METHOD.md §1.5)
>
> Scale effort to size: a STANDARD question gets a 2-minute inline brainstorm; a big FULL lock gets a real planning pass (optionally a cheap "scoping agent" that maps the source landscape first).

```
SUB-QUESTION DECOMPOSITION:  Break the contract's question into N independent sub-questions. N drives agent count.

PER SUB-QUESTION:
  SUB-Q 1: <one sentence>
    SOURCE MAP:        Named tier-1 sources for THIS sub-q (sites, repos, doc trees, forums) — not "search the web".
    QUERY SET:         5-10 actual query strings, run through the §2 ladder (authority / filetype / forum / contrarian / synonym).
    GOOD ANSWER:       The concrete artifact that closes it.
    AGENT ASSIGNMENT:  Which subagent owns it; what is OUT of its scope.
  SUB-Q 2: ...
  SUB-Q 3: ...

PARALLELIZATION DECISION:  Fan out (independent sub-qs, different sources) vs. go deep (each query needs the prior answer). (§6)
COUNCIL PLAN:              Will findings go to an LLM council (§6.5)? If so, what exact decision must the council reach?
```

**Review the plan before launching agents.** Cheap to fix on paper, expensive after fan-out.
