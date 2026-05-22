# Parallel browser-harness agents — concrete recipe

> Companion to METHOD.md §6 (fan-out) and `scripts/browser-harness-headless.sh`.
> Use this when running multiple research subagents in parallel and each needs to browse independently.

---

## Why you need one port per agent

`browser-harness` talks to Chrome over the Chrome DevTools Protocol (CDP). CDP is a per-port, single-client protocol: if two agents share the same port (and the same `--user-data-dir`), they share tabs, cookies, and history. Navigation by one agent will disrupt the other mid-read. For parallel research, isolation is mandatory.

The three things each agent must own exclusively:

| Resource | What happens if shared | How to isolate |
|---|---|---|
| CDP port | Agents collide, tabs get hijacked | Unique `BH_PORT` (9223, 9224, 9225 …) |
| Chrome profile directory | Session state, cookies, cache bleed between agents | Default profile is now keyed to port: `~/.cache/bh-chrome-profile-<PORT>` |
| `BU_NAME` env var | `browser-harness` uses this to select the target Chrome when multiple instances are visible on the network | Unique `BU_NAME` per agent (`agent-a`, `agent-b` …) |

---

## Step-by-step: launching N parallel agents

### 1. Launch one Chrome per agent (orchestrator, before briefing subagents)

```bash
BH_PORT=9223 ./scripts/browser-harness-headless.sh start  # agent A
BH_PORT=9224 ./scripts/browser-harness-headless.sh start  # agent B
BH_PORT=9225 ./scripts/browser-harness-headless.sh start  # agent C
```

Each prints its own `export BU_CDP_URL=http://127.0.0.1:<PORT>`. Record these — they go into each agent's brief.

### 2. Brief each agent with its own port and name

In each subagent brief, set:

```
BROWSER PORT: 9223
```

And the agent begins its session by exporting:

```bash
export BU_CDP_URL=http://127.0.0.1:9223
export BU_NAME=agent-a
```

`BU_NAME` is optional when only one Chrome is running; it is required when multiple are running on different ports so `browser-harness` can route to the right one.

### 3. First invocation: restart_daemon() in its own call

After Chrome relaunches or when the daemon may hold a stale CDP socket, `restart_daemon()` must be its own invocation. Do NOT combine it with a navigation call in the same heredoc — it fails mid-call.

```bash
# correct: restart first, navigate second
BU_CDP_URL=http://127.0.0.1:9223 BU_NAME=agent-a browser-harness <<'PY'
restart_daemon()
PY

BU_CDP_URL=http://127.0.0.1:9223 BU_NAME=agent-a browser-harness <<'PY'
new_tab("https://github.com/some/repo")
import time; time.sleep(3)
print(js("document.body.innerText.slice(0,4000)"))
PY
```

### 4. Extract text, not screenshots

Always use `js("document.body.innerText.slice(0, N)")` to read page content. Avoid `capture_screenshot()` for text extraction — screenshots encode as base64 and consume large amounts of context window for no benefit over plain text.

```python
# preferred
print(js("document.body.innerText.slice(0, 6000)"))

# avoid for text extraction
capture_screenshot()  # only useful when visual layout matters
```

### 5. Each agent writes its FINDING to its own file

Name findings files by agent or angle so the orchestrator can merge them unambiguously:

```
findings/angle-a-format-priority.md
findings/angle-b-practitioner-reality.md
findings/angle-c-contrarian.md
```

Each agent returns only a one-line pointer to its findings file. The orchestrator reads and merges the files; it does not receive the raw findings body in its context.

### 6. Cleanup by profile path only

When an agent finishes, clean its isolated profile and nothing else:

```bash
BH_PORT=9223 ./scripts/browser-harness-headless.sh clean  # removes bh-chrome-profile-9223 only
BH_PORT=9224 ./scripts/browser-harness-headless.sh clean
BH_PORT=9225 ./scripts/browser-harness-headless.sh clean
```

**Never** run `pkill chrome` or `pkill -f "Google Chrome"` — that kills the user's real browser. The `clean` subcommand uses `pkill -f "$PROFILE"` which targets only the specific profile path.

---

## Port allocation convention

| Port | Usage |
|---|---|
| 9222 | Default single-agent / serial research |
| 9223 | Parallel agent A (first parallel slot) |
| 9224 | Parallel agent B |
| 9225 | Parallel agent C |
| 9226 | Parallel agent D |
| 9227 | Parallel agent E |

Do not reuse a port until its Chrome instance has been cleaned. Check for stale instances: `lsof -i :9223` (macOS/Linux).

---

## Summary checklist

- [ ] One `BH_PORT` + one `--user-data-dir` per parallel agent (script handles the profile key by default)
- [ ] `BU_NAME` declared per agent in its brief
- [ ] `restart_daemon()` in its own invocation, then navigate separately
- [ ] `js("document.body.innerText...")` for text extraction (not screenshots)
- [ ] Findings written to per-agent files, pointers returned to orchestrator
- [ ] `BH_PORT=<PORT> ./scripts/browser-harness-headless.sh clean` after each agent finishes
