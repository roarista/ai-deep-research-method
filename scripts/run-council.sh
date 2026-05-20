#!/usr/bin/env bash
# LLM council (METHOD.md §6.5): send ONE merged findings doc + a council brief to three
# INDEPENDENT model CLIs, each blind to the others, and collect their verdicts.
# Agreement across three = strong signal; disagreement localizes where the evidence is thin.
#
# Reference CLIs (edit to match what you have installed):
#   claude  -> Claude Code            (https://claude.com/claude-code)
#   codex   -> OpenAI Codex CLI
#   kimi    -> Moonshot Kimi CLI      (invoke: kimi --print -p "<prompt>"; do NOT pass -m <model>)
#
# Usage:
#   ./run-council.sh FINDINGS.md COUNCIL_BRIEF.md [OUTDIR]
#
# Output: OUTDIR/verdict-{claude,codex,kimi}.md  (default OUTDIR=./council-out)
set -euo pipefail

FINDINGS="${1:?usage: run-council.sh FINDINGS.md COUNCIL_BRIEF.md [OUTDIR]}"
BRIEF="${2:?need a council brief file}"
OUTDIR="${3:-./council-out}"
mkdir -p "$OUTDIR"

PROMPT="$(cat "$BRIEF")

=== EVIDENCE: MERGED FINDINGS (read only this; cite the specific FINDING behind each claim) ===
$(cat "$FINDINGS")"

run_member () {  # name  command...
  local name="$1"; shift
  echo "→ council member: $name"
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "  SKIP — '$1' not on PATH"; return
  fi
  "$@" >"$OUTDIR/verdict-$name.md" 2>"$OUTDIR/verdict-$name.err" \
    && echo "  done -> $OUTDIR/verdict-$name.md" \
    || echo "  FAILED — see $OUTDIR/verdict-$name.err"
}

# Each member is briefed identically and independently. Adjust flags to your CLIs.
run_member claude claude -p "$PROMPT"
run_member codex  codex  exec   "$PROMPT"
run_member kimi   kimi   --print -p "$PROMPT"

echo
echo "Verdicts collected in $OUTDIR/. Read all three; treat disagreement as the next research gap, not a coin-flip."
