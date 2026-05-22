#!/usr/bin/env bash
# Headless depth-browsing for the research method (METHOD.md §3, "follow the authority chain").
# Launches an ISOLATED headless Chrome on a debug port so research agents can read
# JS-rendered pages and navigate repo/doc trees WITHOUT touching your real browser.
#
# Requires: Google Chrome + browser-harness (https://github.com/browser-use/browser-harness)
#   uv tool install -e .   # from the browser-harness clone -> `browser-harness` on PATH
#
# Usage (single instance):
#   ./browser-harness-headless.sh start     # launch headless Chrome on default port 9222
#   ./browser-harness-headless.sh stop      # kill ONLY this debug instance (keeps profile cache)
#   ./browser-harness-headless.sh clean     # stop AND delete the profile cache — run this AFTER research
#   ./browser-harness-headless.sh url       # print the BU_CDP_URL to export
#
# PARALLEL AGENTS — BH_PORT is the parallel-agent hook:
#   Each parallel research subagent needs its OWN port, its OWN --user-data-dir, and its OWN BU_NAME.
#   BH_PROFILE defaults to a path keyed to BH_PORT so parallel instances never share a profile.
#   Launch N agents on ports 9223–9227+ before handing briefs to subagents:
#
#   BH_PORT=9223 ./browser-harness-headless.sh start   # agent A
#   BH_PORT=9224 ./browser-harness-headless.sh start   # agent B
#   BH_PORT=9225 ./browser-harness-headless.sh start   # agent C
#
#   Each subagent brief declares which port it owns (BROWSER PORT: 9223) and sets:
#     export BU_CDP_URL=http://127.0.0.1:9223
#     export BU_NAME=agent-a        # unique name — browser-harness uses this for multi-instance routing
#
#   To clean up agent A only:
#     BH_PORT=9223 ./browser-harness-headless.sh clean
#
#   See docs/parallel-agents.md for the full recipe.
#
# CLEANUP IS MANDATORY (METHOD.md §6.6): the headless profile accumulates page cache, and any
# fetched pages / downloaded files pile up on disk. Always `clean` when the research pass is done —
# leaving profiles around fills the drive over many runs.
#
# Drive it (read-only) from an agent shell:
#   export BU_CDP_URL=http://127.0.0.1:9222
#   BU_CDP_URL=http://127.0.0.1:9222 browser-harness <<'PY'
#   new_tab("https://github.com/some/repo/tree/main/tests")
#   import time; time.sleep(3)
#   # Prefer js() over capture_screenshot() — far cheaper on context.
#   print(js("document.body.innerText.slice(0,4000)"))
#   PY
set -euo pipefail

PORT="${BH_PORT:-9222}"
# Default profile path is keyed to the port so parallel agents never share a profile directory.
PROFILE="${BH_PROFILE:-$HOME/.cache/bh-chrome-profile-${PORT}}"
CHROME="${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

case "${1:-start}" in
  start)
    mkdir -p "$PROFILE"
    "$CHROME" --headless=new \
      --remote-debugging-port="$PORT" --user-data-dir="$PROFILE" \
      --no-first-run --no-default-browser-check >/dev/null 2>&1 &
    sleep 2
    echo "headless Chrome up on port $PORT (profile: $PROFILE)"
    echo "export BU_CDP_URL=http://127.0.0.1:$PORT"
    echo "NOTE: if the daemon holds a stale socket after relaunch, run restart_daemon()"
    echo "      in its OWN browser-harness invocation FIRST, then navigate separately."
    echo "      (Don't combine restart_daemon() + new_tab() in one heredoc — it fails mid-call.)"
    ;;
  stop)
    # Kill ONLY this debug instance by its unique profile path. Never pkill generic 'chrome'.
    pkill -f "$PROFILE" && echo "stopped debug Chrome ($PROFILE)" || echo "nothing to stop"
    ;;
  clean)
    # Stop the instance, then delete its profile cache. Run this AFTER every research pass.
    pkill -f "$PROFILE" 2>/dev/null && echo "stopped debug Chrome ($PROFILE)" || echo "(not running)"
    sleep 1
    # Safety: only remove a path that actually looks like our isolated bh profile.
    case "$PROFILE" in
      *bh-chrome-profile*)
        before=$(du -sh "$PROFILE" 2>/dev/null | cut -f1)
        rm -rf "$PROFILE" && echo "removed profile cache ($PROFILE${before:+, was $before})" ;;
      *)
        echo "REFUSING to rm '$PROFILE' — doesn't look like a bh isolated profile. Delete manually if intended." >&2
        exit 1 ;;
    esac
    echo "cleanup done. (Also remove any pages/files your agents saved outside this profile.)"
    ;;
  url)
    echo "http://127.0.0.1:$PORT"
    ;;
  *)
    echo "usage: $0 {start|stop|clean|url}" >&2; exit 1 ;;
esac
