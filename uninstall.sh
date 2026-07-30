#!/bin/sh
# VibePerks for Codex uninstaller (local/dev).
#
# Removes the managed block that install.sh added to your shell rc, so the sponsor
# line stops loading in new shells. Remove the Codex plugin hooks through Codex's own
# plugin system separately. Your local config/cache in ~/.vibeperks is left untouched;
# delete that directory yourself if you also want to remove your device token and
# cached ad.
set -eu

cd "$(dirname "$0")"
MARK_BEGIN="# >>> vibeperks-codex >>>"
MARK_END="# <<< vibeperks-codex <<<"

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$RC" ] || continue
  if grep -qF "$MARK_BEGIN" "$RC"; then
    tmp="$(mktemp)"
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
      $0==b {skip=1} skip && $0==e {skip=0; next} !skip {print}
    ' "$RC" >"$tmp"
    mv "$tmp" "$RC"
    echo "Removed the VibePerks block from $RC"
  fi
done

echo "Uninstalled. Open a new shell to apply. Delete ~/.vibeperks to also remove your token and cache."
