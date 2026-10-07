#!/bin/bash
# Summit "feel" setup: terminal, shell, tools, editor themes, desktop widgets.
#
#   install.sh            put everything in place again (safe to re-run; changes nothing that is already right)
#   install.sh --layout   also place the desktop widgets again (replaces the widgets this setup owns)
#   install.sh --save     copy your current versions of the managed dotfiles back into this folder
#
# Nothing here needs root. The few root steps are printed at the end.
# A file that would be overwritten with different content is first copied to ~/.local/state/summit/backup-<time>/.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$HERE/home
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=$HOME/.local/state/summit/backup-$STAMP
say()  { printf '%s\n' "$*"; }
note() { printf '  %s\n' "$*"; }

# dotfiles this setup owns: always brought to the stored version
OWNED=(
  .zshrc .zshenv .zprofile
  .config/zsh/p10k.zsh .config/zsh/keys.md .config/zsh/ls_colors.zsh .config/zsh/welcome.zsh
  .config/kitty/kitty.conf .config/kitty/summit.conf .config/kitty/tab_bar.py
  .config/atuin/config.toml .config/atuin/themes/summit.toml
  .config/fzf/fzfrc .config/fontconfig/fonts.conf .config/nvim/init.lua
  .claude/statusline.sh .local/bin/wall .local/share/applications/kitty.desktop
)
# files you keep editing yourself: only created when missing
SEED=( .config/mise/config.toml .config/Code/User/settings.json .config/Cursor/User/settings.json )

if [[ ${1:-} == --save ]]; then
  for f in "${OWNED[@]}" "${SEED[@]}"; do
    [[ -e $HOME/$f ]] || continue
    cmp -s "$HOME/$f" "$SRC/$f" 2>/dev/null && continue
    install -D -m "$(stat -c %a "$HOME/$f")" "$HOME/$f" "$SRC/$f" && note "saved $f"
  done
  mkdir -p "$SRC/.local/share/zsh/site-functions"
  cp -u "$HOME"/.local/share/zsh/site-functions/_* "$SRC/.local/share/zsh/site-functions/" 2>/dev/null
  say "saved."; exit 0
fi

say "0. look (colours, icons, cursor, fonts)"
bash "$HERE/look/look.sh"

say "1. downloads (kitty, zsh plugins, CLI tools)"
bash "$HERE/fetch.sh" | sed 's/^/  /'

say "2. dotfiles"
changed=0
for f in "${OWNED[@]}"; do
  [[ -e $SRC/$f ]] || { note "missing from this folder: $f"; continue; }
  if cmp -s "$SRC/$f" "$HOME/$f" 2>/dev/null; then continue; fi
  if [[ -e $HOME/$f ]]; then install -D -m 644 "$HOME/$f" "$BACKUP/$f"; fi
  install -D -m "$(stat -c %a "$SRC/$f")" "$SRC/$f" "$HOME/$f" && note "installed $f" && changed=1
done
for f in "${SEED[@]}"; do
  [[ -e $HOME/$f || ! -e $SRC/$f ]] || { install -D -m 644 "$SRC/$f" "$HOME/$f" && note "created $f" && changed=1; }
done
mkdir -p "$HOME/.local/share/zsh/site-functions"
cp -n "$SRC"/.local/share/zsh/site-functions/_* "$HOME/.local/share/zsh/site-functions/" 2>/dev/null
(( changed )) || note "all up to date"
[[ -d $BACKUP ]] && note "previous versions kept in $BACKUP"

say "3. terminal definition for kitty (for programs that do not inherit it)"
T=$HOME/.local/kitty.app/lib/kitty/terminfo/x/xterm-kitty
if [[ -r $T ]]; then cmp -s "$T" "$HOME/.terminfo/x/xterm-kitty" 2>/dev/null || install -D -m 644 "$T" "$HOME/.terminfo/x/xterm-kitty"; fi

say "4. tool configs and syntax themes"
bash "$HERE/tools/install.sh" | sed 's/^/  /'

say "5. widgets"
bash "$HERE/widgets/install.sh" 2>&1 | tail -3 | sed 's/^/  /'

say "6. editor theme (VS Code, Cursor)"
for ed in code cursor; do
  command -v $ed >/dev/null || continue
  if $ed --list-extensions --show-versions 2>/dev/null | grep -qx 'summit.summit-theme@1.0.0'; then note "$ed: already installed"
  else $ed --install-extension "$HERE/vscode/summit-theme-1.0.0.vsix" --force 2>/dev/null | tail -1 | sed 's/^/  /'; fi
done

say "7. desktop settings"
kset() {  # kset FILE KEY VALUE GROUP...   writes only when the value differs
  local file=$1 key=$2 val=$3; shift 3; local -a g=(); for x in "$@"; do g+=(--group "$x"); done
  [[ $(kreadconfig6 --file "$file" "${g[@]}" --key "$key" 2>/dev/null) == "$val" ]] && return 0
  kwriteconfig6 --file "$file" "${g[@]}" --key "$key" "$val" && note "$file: $key = $val"
}
kset kdeglobals TerminalApplication kitty General
kset kdeglobals TerminalService kitty.desktop General
kset kwriterc "Color Theme" Summit "KTextEditor Renderer"
kset kwriterc "Auto Color Theme Selection" false "KTextEditor Renderer"
kset kglobalshortcutsrc _launch $'Ctrl+Alt+T\tMeta+Return' services kitty.desktop
kset kglobalshortcutsrc _launch none services org.kde.konsole.desktop
command -v flatpak >/dev/null && flatpak override --user --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro
fc-cache -f >/dev/null 2>&1

# Plasma style "Summit Glass": the default style with the panel fill at 42% instead of 85%
T=$HOME/.local/share/plasma/desktoptheme/summit-glass
if [[ ! -d $T ]]; then
  cp -r /usr/share/plasma/desktoptheme/default "$T" && cp "$HERE/plasma-style/metadata.json" "$T/" \
    && cp "$HERE/plasma-style/panel-background.svgz" "$T/translucent/widgets/" && note "Plasma style Summit Glass installed"
fi
[[ $(kreadconfig6 --file plasmarc --group Theme --key name) == summit-glass ]] || plasma-apply-desktoptheme summit-glass >/dev/null

say "8. first-time data"
ATUIN=$HOME/.local/share/mise/installs/atuin/latest/.mise-bins/atuin
if [[ -x $ATUIN && ! -e $HOME/.local/share/atuin/history.db && -s $HOME/.zsh_history ]]; then
  ATUIN_SESSION=$("$ATUIN" uuid) HISTFILE=$HOME/.zsh_history "$ATUIN" import zsh 2>&1 | tail -1 | sed 's/^/  /'
fi
# the picture on the terminal's welcome card, drawn from the current wallpaper
[[ -r $HOME/.cache/summit/welcome.png.kitty ]] || "$HOME/.local/bin/wall" card >/dev/null 2>&1
# accent colour from the wallpaper, for Plasma and kitty (kitty.conf includes accent.conf)
[[ -r $HOME/.config/kitty/accent.conf ]] || "$HOME/.local/bin/wall" accent >/dev/null 2>&1
TLDR=$HOME/.local/share/mise/installs/tealdeer/latest/tldr
[[ -x $TLDR && ! -d $HOME/.cache/tealdeer/tldr-pages ]] && "$TLDR" --update 2>&1 | tail -1 | sed 's/^/  /'

if [[ ${1:-} == --layout ]]; then
  say "9. desktop widget layout"
  bash "$HERE/widgets/apply-layout.sh" | sed 's/^/  /'
fi

cat <<'TXT'

Steps that need your password (once):
  chsh -s /usr/bin/zsh                   make zsh the login shell (kitty already starts zsh either way)
  sudo dnf install -y kitty-terminfo     lets programs run through sudo (sudo nano, sudo btop) recognise the terminal
New terminals pick everything up. A changed shortcut or default terminal takes effect at the next login.
TXT
