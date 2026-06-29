#!/bin/sh
# VibePerks for Codex installer (local/dev).
#
# Builds the adapter binary and adds a managed block to your shell rc that sources the
# VibePerks shell integration. Re-running is safe: the managed block is replaced, not
# duplicated. The Codex plugin itself (hooks) is installed through Codex's plugin
# system; this script handles the binary + shell rendering surface.
set -eu

cd "$(dirname "$0")"
ROOT="$(pwd)"
MARK_BEGIN="# >>> vibeperks-codex >>>"
MARK_END="# <<< vibeperks-codex <<<"

echo "Building the adapter binary..."
sh ./build.sh >/dev/null

rc_for_shell() {
  case "${SHELL##*/}" in
    zsh) printf '%s\n' "$HOME/.zshrc" ;;
    *) printf '%s\n' "$HOME/.bashrc" ;;
  esac
}

RC="$(rc_for_shell)"
BLOCK="$MARK_BEGIN
export VIBEPERKS_CODEX_BIN=\"$ROOT/bin/vibeperks-codex\"
. \"$ROOT/scripts/shell-integration.sh\"
$MARK_END"

touch "$RC"
# Drop any previous managed block, then append the current one.
tmp="$(mktemp)"
awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
  $0==b {skip=1} skip && $0==e {skip=0; next} !skip {print}
' "$RC" >"$tmp"
printf '%s\n' "$BLOCK" >>"$tmp"
mv "$tmp" "$RC"

echo "Installed. Open a new shell, then run: vibeperks-codex login <device-token>"
