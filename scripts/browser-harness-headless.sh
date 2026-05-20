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
#   ./browser-harness-headless.sh stop      # kill ONLY this debug instance (keeps profile cache)
#   ./browser-harness-headless.sh clean      # stop AND delete the profile cache — run this AFTER research
#   ./browser-harness-headless.sh url        # print the BU_CDP_URL to export
#
# CLEANUP IS MANDATORY (METHOD.md §6.6): the headless profile accumulates page cache, and any
# fetched pages / downloaded files pile up on disk. Always `clean` when the research pass is done —
# leaving profiles around fills the drive over many runs.
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
