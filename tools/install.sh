#!/bin/bash
# Install the Summit configs for the terminal tools (bat, delta, lazygit, yazi, btop, tmux,
# eza, nano, fastfetch, tldr, lazydocker, glow) and the syntax themes (bat, Kate, Neovim).
#
#   install.sh                 into ~/.config and ~/.local/share (the real thing)
#   install.sh CONFIG DATA     into another pair of directories (used by the test session)
#
# Safe to run again: files are simply written over with the versions kept here.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
SYNTAX=$HERE/../syntax
LIVE_C=$HOME/.config
C=${1:-$LIVE_C}
D=${2:-$HOME/.local/share}

put() {  # put SRC DEST: copy, pointing paths at $C when it is not the live config directory
  install -D -m 644 "$1" "$2"
  sed -i "s|@CONFIG@|$C|g" "$2"
  if [[ $C != "$LIVE_C" ]]; then
    sed -i -e "s|$LIVE_C|$C|g" -e "s|~/.config|$C|g" "$2"
  fi
}

put "$HERE/bat/config"               "$C/bat/config"
put "$HERE/btop/btop.conf"           "$C/btop/btop.conf"
put "$HERE/btop/themes/summit.theme" "$C/btop/themes/summit.theme"
put "$HERE/eza/theme.yml"            "$C/eza/theme.yml"
put "$HERE/fastfetch/config.jsonc"   "$C/fastfetch/config.jsonc"
put "$HERE/git/delta.gitconfig"      "$C/git/delta.gitconfig"
put "$HERE/glow/glow.yml"            "$C/glow/glow.yml"
put "$HERE/glow/summit.json"         "$C/glow/summit.json"
put "$HERE/lazydocker/config.yml"    "$C/lazydocker/config.yml"
put "$HERE/lazygit/config.yml"       "$C/lazygit/config.yml"
put "$HERE/nano/nanorc"              "$C/nano/nanorc"
put "$HERE/tealdeer/config.toml"     "$C/tealdeer/config.toml"
put "$HERE/tmux/tmux.conf"           "$C/tmux/tmux.conf"
put "$HERE/yazi/yazi.toml"           "$C/yazi/yazi.toml"
put "$HERE/yazi/theme.toml"          "$C/yazi/theme.toml"

# syntax themes: bat (also used by delta and yazi), Kate/KWrite, Neovim
install -D -m 644 "$SYNTAX/bat/themes/Summit.tmTheme" "$C/bat/themes/Summit.tmTheme"
install -D -m 644 "$SYNTAX/kate/summit.theme"         "$D/org.kde.syntax-highlighting/themes/summit.theme"
install -D -m 644 "$SYNTAX/nvim/colors/summit.lua"    "$C/nvim/colors/summit.lua"
# bat exits 0 even when a theme does not parse, so check its output and the resulting theme list
out=$(bat cache --build 2>&1) || { echo "$out" >&2; exit 1; }
if grep -qi 'failed to load' <<<"$out" || ! bat --list-themes | grep -qx Summit; then
  echo "bat did not accept the Summit theme:" >&2; echo "$out" >&2; exit 1
fi

# git: pull the delta settings in (once)
if [[ $C == "$LIVE_C" ]]; then
  git config --global --get-all include.path 2>/dev/null | grep -qxF '~/.config/git/delta.gitconfig' \
    || git config --global --add include.path '~/.config/git/delta.gitconfig'
else
  printf '[include]\n\tpath = %s/git/delta.gitconfig\n' "$C" > "$C/git/config"
fi
echo "tool configs installed into $C"
