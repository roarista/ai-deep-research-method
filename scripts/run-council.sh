#!/usr/bin/env bash
# LLM council (METHOD.md §6.5): send ONE merged findings doc + a council brief to three
# INDEPENDENT model CLIs, each blind to the others, and collect their verdicts.
# Agreement across three = strong signal; disagreement localizes where the evidence is thin.
#
# The method is MODEL-AGNOSTIC: any three genuinely different, terminal-driveable models work.
# Reference CLIs this was built with (edit the run_member lines below to match yours):
#   claude  -> Claude Code        https://claude.com/claude-code
#   codex   -> OpenAI Codex CLI   https://github.com/openai/codex
#   kimi    -> Moonshot Kimi CLI  https://github.com/MoonshotAI/kimi-cli   (check `kimi --help` for current flags)
# Swappable alternatives / additional members:
#   gemini  -> Gemini CLI         https://github.com/google-gemini/gemini-cli
#   any model via OpenRouter      https://openrouter.ai  (one endpoint -> GPT / Llama / DeepSeek / Qwen / Mistral / ...)
# The only rule: THREE DISTINCT models, each briefed independently (none sees another's answer).
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

export PROMPT="$(cat "$BRIEF")

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

# Each member is briefed identically and independently. Adjust flags to YOUR installed CLIs
# (run `<cli> --help` to confirm the non-interactive / print flag for your version).
run_member claude claude -p      "$PROMPT"
run_member codex  codex  exec    "$PROMPT"
run_member kimi   kimi   --print -p "$PROMPT"

# --- swappable / additional members: uncomment to use, comment out any above ---
# run_member gemini gemini -p "$PROMPT"
# OpenRouter (reach any model through one API; set OPENROUTER_API_KEY and pick a model):
# run_member openrouter sh -c 'curl -s https://openrouter.ai/api/v1/chat/completions \
#   -H "Authorization: Bearer $OPENROUTER_API_KEY" -H "Content-Type: application/json" \
#   -d "$(jq -n --arg m "deepseek/deepseek-chat" --arg c "$PROMPT" \
#        "{model:\$m,messages:[{role:\"user\",content:\$c}]}")" \
#   | jq -r ".choices[0].message.content"'

echo
echo "Verdicts collected in $OUTDIR/. Read all three; treat disagreement as the next research gap, not a coin-flip."
