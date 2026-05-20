#!/usr/bin/env bash
# Headless depth-browsing for the research method (METHOD.md §3, "follow the authority chain").
# Launches an ISOLATED headless Chrome on a debug port so research agents can read
# JS-rendered pages and navigate repo/doc trees WITHOUT touching your real browser.
#
# Requires: Google Chrome + browser-harness (https://github.com/browser-use/browser-harness)
#   uv tool install -e .   # from the browser-harness clone -> `browser-harness` on PATH
#
# Usage:
#   ./browser-harness-headless.sh start     # launch headless Chrome
#   ./browser-harness-headless.sh stop      # kill ONLY this debug instance
#   ./browser-harness-headless.sh url        # print the BU_CDP_URL to export
#
# Then drive it (read-only) from any agent shell:
#   BU_CDP_URL=http://127.0.0.1:9222 browser-harness <<'PY'
#   new_tab("https://github.com/some/repo/tree/main/tests")
#   import time; time.sleep(3)
#   print(js("document.body.innerText.slice(0,4000)"))
#   PY
set -euo pipefail

PORT="${BH_PORT:-9222}"
PROFILE="${BH_PROFILE:-$HOME/.cache/bh-chrome-profile}"
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
    ;;
  stop)
    # Kill ONLY this debug instance by its unique profile path. Never pkill generic 'chrome'.
    pkill -f "$PROFILE" && echo "stopped debug Chrome ($PROFILE)" || echo "nothing to stop"
    ;;
  url)
    echo "http://127.0.0.1:$PORT"
    ;;
  *)
    echo "usage: $0 {start|stop|url}" >&2; exit 1 ;;
esac
