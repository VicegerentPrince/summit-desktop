#!/bin/bash
# Downloads for the terminal setup. User-level only, safe to re-run: every step skips what is already there.
#   kitty (official build)  -> ~/.local/kitty.app
#   zsh plugins             -> ~/.local/share/zsh/plugins
#   CLI tools               -> mise (global config)
set -u
LOG=$HOME/.local/state/summit/fetch.log
mkdir -p "$HOME/.local/state/summit" "$HOME/.cache/summit/dl" "$HOME/.local/bin" "$HOME/.local/share/zsh/plugins"
say() { printf '%s  %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG"; }
retry() { local n=0; until "$@"; do n=$((n+1)); [ $n -ge 5 ] && return 1; say "  retry $n: $1 $2"; sleep $((10*n)); done; }

# ---- kitty ------------------------------------------------------------------
KV=${KITTY_VERSION:-0.49.2}
if [ -x "$HOME/.local/kitty.app/bin/kitty" ] && "$HOME/.local/kitty.app/bin/kitty" --version 2>/dev/null | grep -q " $KV "; then
    say "kitty $KV already installed"
else
    cd "$HOME/.cache/summit/dl" || exit 1
    F=kitty-$KV-x86_64.txz
    WANT=$(gh api "repos/kovidgoyal/kitty/releases/tags/v$KV" --jq ".assets[] | select(.name==\"$F\") | .digest" 2>/dev/null | sed 's/^sha256://')
    ok=0
    for try in 1 2 3 4 5; do
        retry curl -fL --retry 5 --retry-delay 5 -C - -o "$F" "https://github.com/kovidgoyal/kitty/releases/download/v$KV/$F" >>"$LOG" 2>&1
        GOT=$(sha256sum "$F" 2>/dev/null | cut -d' ' -f1)
        if [ -n "$WANT" ] && [ "$GOT" = "$WANT" ]; then ok=1; break; fi
        if [ -z "$WANT" ] && xz -t "$F" 2>/dev/null; then ok=1; say "  no published digest; archive passes xz integrity test"; break; fi
        say "  checksum mismatch on try $try (got ${GOT:0:16}…, want ${WANT:0:16}…); downloading again"; rm -f "$F"
    done
    if [ $ok = 1 ]; then
        rm -rf "$HOME/.local/kitty.app.new"; mkdir -p "$HOME/.local/kitty.app.new"
        if tar -C "$HOME/.local/kitty.app.new" -xJf "$F"; then
            rm -rf "$HOME/.local/kitty.app.old"; [ -d "$HOME/.local/kitty.app" ] && mv "$HOME/.local/kitty.app" "$HOME/.local/kitty.app.old"
            mv "$HOME/.local/kitty.app.new" "$HOME/.local/kitty.app"; rm -rf "$HOME/.local/kitty.app.old"
            ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
            ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
            say "kitty $("$HOME/.local/kitty.app/bin/kitty" --version) installed (sha256 verified: ${WANT:+yes}${WANT:-n/a})"
        else say "FAILED: kitty archive did not extract"; fi
    else say "FAILED: kitty download"; fi
fi

# ---- zsh plugins (shallow clones) --------------------------------------------
P=$HOME/.local/share/zsh/plugins
for r in romkatv/powerlevel10k Aloxaf/fzf-tab hlissner/zsh-autopair zsh-users/zsh-completions; do
    d=$P/$(basename "$r")
    if [ -d "$d/.git" ]; then say "plugin $(basename "$r") already present ($(git -C "$d" log -1 --format=%h))"; continue; fi
    rm -rf "$d"
    if retry git clone -q --depth 1 "https://github.com/$r.git" "$d" >>"$LOG" 2>&1; then say "plugin $(basename "$r") $(git -C "$d" log -1 --format='%h %ad' --date=short)"; else say "FAILED: clone $r"; fi
done

# ---- Liquid Glass widgets (jaxparrow07, GPL-3.0), pinned; widgets/liquidglass.sh installs them with fixes
V=$HOME/.local/share/summit/vendor/liquidglass-kde-widgets
PIN=ff196b4a688eccc7c8c858b3d53a76d8e7055719
if [ "$(git -C "$V" rev-parse HEAD 2>/dev/null)" = "$PIN" ]; then say "liquidglass widgets already at ${PIN:0:7}"
else
    rm -rf "$V"; mkdir -p "$(dirname "$V")"
    if retry git clone -q https://github.com/jaxparrow07/liquidglass-kde-widgets.git "$V" >>"$LOG" 2>&1 && git -C "$V" checkout -q "$PIN" >>"$LOG" 2>&1; then
        say "liquidglass widgets ${PIN:0:7}"
    else say "FAILED: liquidglass widgets"; fi
fi

# ---- CLI tools through mise ---------------------------------------------------
MISE=$HOME/.local/bin/mise
if [ ! -x "$MISE" ]; then
    say "installing mise (runtime and tool manager) into ~/.local/bin"
    curl -fsSL https://mise.run | MISE_INSTALL_PATH="$MISE" sh >>"$LOG" 2>&1 || say "FAILED: mise install"
fi
TOOLS="atuin delta lazygit yazi tealdeer lazydocker dust duf glow"
export GITHUB_TOKEN=${GITHUB_TOKEN:-$(gh auth token 2>/dev/null)}   # only for this process: avoids GitHub's anonymous rate limit
export MISE_JOBS=2 MISE_HTTP_TIMEOUT=120
for t in $TOOLS; do
    if "$MISE" ls --global "$t" 2>/dev/null | grep -q "$t"; then say "tool $t already managed: $("$MISE" ls --global "$t" 2>/dev/null | awk '{print $2}' | head -1)"; continue; fi
    if retry "$MISE" use -g "$t@latest" >>"$LOG" 2>&1; then say "tool $t $("$MISE" ls --global "$t" 2>/dev/null | awk '{print $2}' | head -1)"; else say "FAILED: mise use -g $t"; fi
done
say "fetch finished"
