# Pre-Research Plan — <short title>

> HEAVY tier. The highest-leverage step: decide what to look for and where, split the question into distinct angles, and write the harness each agent gets — all BEFORE any agent runs. A bad plan multiplied across N parallel agents wastes N× the compute. (METHOD.md §1.5)
>
> Scale the brainstorm to the question. For a big lock, optionally fan out a cheap throwaway "scoping agent" first that maps the source landscape and reports which sites/forums/repos are worth the real agents' time.

```
ANGLE DECOMPOSITION:  Split the question into N angles — different PARTS and different PERSPECTIVES
                      (e.g. official-docs / practitioner-reality / contrarian-limitations / cost).
                      N drives agent count. Angles should overlap as little as possible.

PER ANGLE:
  ANGLE 1: <one sentence>
    PERSPECTIVE:   What lens this agent researches from, and why it's distinct from the others.
    SOURCE MAP:    Named tier-1 sources for THIS angle (sites, repos, doc trees, forums) — not "search the web".
    QUERY SET:     5-10 actual query strings, run through the §2 ladder (authority / filetype / forum / contrarian / synonym).
    GOOD ANSWER:   The concrete artifact that closes it.
    THE HARNESS:   The exact subagent brief this agent gets (subagent-brief.md) — scope, sources, citation rule, bias guard.
  ANGLE 2: ...
  ANGLE 3: ...

PARALLELIZATION:  Fan out (independent angles) vs. go deep (each query needs the prior answer). (§6)
COUNCIL PLAN:     The exact decision the council (§6.5) must reach once findings land.
```

**Review the plan before launching agents.** Cheap to fix on paper, expensive after fan-out.
