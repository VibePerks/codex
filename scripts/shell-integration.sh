# VibePerks for Codex - shell integration (bash/zsh).
#
# Source this file from your shell rc. It renders the cached VibePerks sponsor line above
# the prompt and in the terminal title while you work in Codex. It makes ZERO network
# calls - it only reads the local ad cache via `vibeperks-codex render`. The network path
# runs in the background from Codex's prompt hook.
#
# Set VIBEPERKS_CODEX_BIN to the vibeperks-codex binary if it is not on PATH.

__vibeperks_codex_bin() {
  if [ -n "${VIBEPERKS_CODEX_BIN:-}" ]; then
    printf '%s\n' "$VIBEPERKS_CODEX_BIN"
  else
    printf '%s\n' "vibeperks-codex"
  fi
}

# __vibeperks_codex_render prints the cached sponsor line (or nothing) and sets the terminal
# title to it. Quiet and instant; never blocks the prompt.
__vibeperks_codex_render() {
  local bin line
  bin="$(__vibeperks_codex_bin)"
  command -v "$bin" >/dev/null 2>&1 || return 0
  line="$("$bin" render 2>/dev/null)" || return 0
  [ -n "$line" ] || return 0
  printf '%s\n' "$line"
  printf '\033]0;%s\007' "$line"
}

if [ -n "${ZSH_VERSION:-}" ]; then
  autoload -Uz add-zsh-hook 2>/dev/null && add-zsh-hook precmd __vibeperks_codex_render
elif [ -n "${BASH_VERSION:-}" ]; then
  case "${PROMPT_COMMAND:-}" in
    *__vibeperks_codex_render*) ;;
    *) PROMPT_COMMAND="__vibeperks_codex_render${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
  esac
fi
