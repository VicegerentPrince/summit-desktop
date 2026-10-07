# ~/.zshrc — interactive zsh. Built for speed: the prompt appears instantly and everything
# else loads behind it. Type `keys` for a one-page reminder of what this setup gives you.
# Part of summit-desktop: https://github.com/VicegerentPrince/summit-desktop

# ---- welcome card: the first shell of a new kitty window (see the file; `welcome off` hides it).
# It is the one thing allowed to print during startup, and only because it comes before the
# instant prompt below. Pure zsh, about 2 ms.
[[ -r $HOME/.config/zsh/welcome.zsh ]] && source $HOME/.config/zsh/welcome.zsh

# ---- instant prompt: must stay here. Nothing else above this may print or ask for input. -------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

ZPLUG=$HOME/.local/share/zsh/plugins
ZCACHE=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
[[ -d $ZCACHE ]] || mkdir -p $ZCACHE

# kitty sets up its shell integration (window title, prompt marks, current directory for new
# tabs) only in the first shell of a window. This does the same for `exec zsh` and nested shells.
if [[ -n $KITTY_INSTALLATION_DIR && -z $TMUX ]] && (( ! $+_ksi_state )) \
   && [[ -r $KITTY_INSTALLATION_DIR/shell-integration/zsh/kitty-integration ]]; then
  export KITTY_SHELL_INTEGRATION=enabled
  autoload -Uz -- $KITTY_INSTALLATION_DIR/shell-integration/zsh/kitty-integration
  kitty-integration
  unfunction kitty-integration
fi

# Run a tool's shell-init command once and reuse its output until that tool changes (another
# version, another path) or is asked for something else. Saves a process start per tool on every
# new shell. The first line of each cache file records what produced it.
zmodload -F zsh/stat b:zstat 2>/dev/null
zmodload zsh/datetime 2>/dev/null
_cached_init() {
  local name=$1 bin=${commands[$2]:-$2}; shift 2
  [[ -x $bin ]] || return 1
  local cache=$ZCACHE/init-$name.zsh stamp first
  local -a st
  zstat -A st -- $bin:A 2>/dev/null                    # st[8] size, st[10] modification time
  stamp="# $bin:A $st[8] $st[10] $*"
  [[ -r $cache ]] && IFS= read -r first < $cache
  if [[ $first != $stamp ]]; then
    { print -r -- $stamp; "$bin" "$@" } >| $cache.$$ 2>/dev/null && mv -f $cache.$$ $cache || { rm -f $cache.$$; return 1 }
  fi
  source $cache
}

# ---- history ------------------------------------------------------------------------------
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY HIST_FIND_NO_DUPS
# Lock the history file itself instead of creating a .LOCK file beside it at every prompt. Besides
# being cheaper, that lock file changed the home folder each time, which made mise redo its whole
# environment check (10 ms) on every prompt instead of its 2 ms "nothing changed" answer.
setopt HIST_FCNTL_LOCK
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT INTERACTIVE_COMMENTS NO_BEEP NO_FLOW_CONTROL

# ---- environment ----------------------------------------------------------------------------
typeset -U path fpath
path=($HOME/.local/bin $path)
export EDITOR=nano VISUAL=nano
export PAGER=less
export GPG_TTY=$TTY                                         # gpg asks for passphrases on this terminal
export LESS='-R -F -i -M --use-color -DPwk -DSkY -DEyk'   # pager: quiet status, amber search hits
[[ -r $HOME/.config/fzf/fzfrc ]] && export FZF_DEFAULT_OPTS_FILE=$HOME/.config/fzf/fzfrc
# man pages through bat, in colour
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"
export MANROFFOPT=-c
[[ -r $HOME/.config/zsh/ls_colors.zsh ]] && source $HOME/.config/zsh/ls_colors.zsh

# A mistyped command answers at once and names the nearest real one. (Fedora's stock handler
# asks PackageKit to search the repositories first: about 4 seconds per typo on this machine.)
# Defined before mise is set up: mise puts its own check in front (it installs a tool that is
# configured but missing) and hands everything else to this.
command_not_found_handler() {
  emulate -L zsh -o extended_glob
  local cmd=$1
  local -a near
  print -ru2 -- "zsh: command not found: $cmd"
  if (( $#cmd > 2 )) && [[ $cmd != */* ]]; then
    near=(${commands[(I)(#a1)${(b)cmd}]} ${aliases[(I)(#a1)${(b)cmd}]} ${functions[(I)(#a1)${(b)cmd}]})
    near=(${(ou)near:#_*})
    (( $#near )) && print -ru2 -- $'\e[38;2;134;147;161m     did you mean \e[38;2;79;209;197m'"${(j:, :)near[1,4]}"$'\e[38;2;134;147;161m?\e[0m'
  fi
  return 127
}

# runtimes and CLI tools (node, pnpm, go, task, atuin, delta, lazygit, yazi, ...)
# mise re-checks its configuration before every prompt, and redoes all of it (10 ms) whenever a
# folder above the current one has changed. The home folder changes constantly (apps rewrite
# their dotfiles there), so the search stops below it: project folders are still watched and
# the global config in ~/.config/mise still applies. A mise.toml placed directly in ~ would not.
export MISE_CEILING_PATHS=$HOME
# Run fresh each time, not through _cached_init: mise writes the PATH it sees into this script,
# so a cached copy would replace the PATH a new shell inherits (a virtualenv, an editor's
# additions) with an old one.
[[ -x $HOME/.local/bin/mise ]] && eval "$($HOME/.local/bin/mise activate zsh)"
[[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# ---- completion -----------------------------------------------------------------------------
fpath=($HOME/.local/share/zsh/site-functions $ZPLUG/zsh-completions/src $fpath)
autoload -Uz compinit
() {
  # Completions come from a cached list. It is rebuilt when a folder that holds completion
  # functions has changed (something was installed or removed), and once a day in any case.
  local dump=$ZCACHE/zcompdump d
  local -a st
  local -i fresh=0 dumped=0
  if zstat -A st +mtime -- $dump 2>/dev/null && (( EPOCHSECONDS - st[1] < 86400 )); then
    fresh=1 dumped=$st[1]
    for d in $fpath; do
      zstat -A st +mtime -- $d 2>/dev/null && (( st[1] > dumped )) && { fresh=0; break }
    done
  fi
  if (( fresh )); then
    compinit -C -d $dump
  else
    compinit -d $dump
    touch $dump                   # compinit leaves an unchanged dump alone; restart the clock
    { zcompile $dump } &!
  fi
}
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path $ZCACHE/compcache
zstyle ':completion:*' menu no                              # fzf-tab draws the menu
zstyle ':completion:*:descriptions' format '[%d]'           # group headers for fzf-tab
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# ---- keys -----------------------------------------------------------------------------------
bindkey -e
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'                          # word motions stop at / and :
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line
bindkey '^[[A' up-line-or-beginning-search      # Up: older commands starting with what is typed
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
bindkey '^[[H' beginning-of-line                # Home
bindkey '^[[F' end-of-line                      # End
bindkey '^[[3~' delete-char                     # Delete
bindkey '^[[1;5C' forward-word                  # Ctrl+Right
bindkey '^[[1;5D' backward-word                 # Ctrl+Left
bindkey '^[[1;3C' forward-word                  # Alt+Right
bindkey '^[[1;3D' backward-word                 # Alt+Left
bindkey '^H' backward-kill-word                 # Ctrl+Backspace
bindkey '^[[3;5~' kill-word                     # Ctrl+Delete
bindkey '^X^E' edit-command-line                # Ctrl+X Ctrl+E: edit the command in $EDITOR

# Esc Esc: put sudo in front of the current command (or of the previous one on an empty line)
_sudo_toggle() {
  [[ -z $BUFFER ]] && zle up-history
  if [[ $BUFFER == sudo\ * ]]; then LBUFFER=${LBUFFER#sudo }; else LBUFFER="sudo $LBUFFER"; fi
}
zle -N _sudo_toggle
bindkey '\e\e' _sudo_toggle

# ---- fuzzy finder ---------------------------------------------------------------------------
# Ctrl+T files, Alt+C directories. Ctrl+R is left to atuin below.
export FZF_CTRL_T_OPTS="--walker-skip .git,node_modules,target,.next,dist --preview '[[ -d {} ]] && eza -1 --icons=always --color=always --group-directories-first {} || bat --color=always --style=numbers --line-range=:200 {}'"
export FZF_ALT_C_OPTS="--walker-skip .git,node_modules,target,.next,dist --preview 'eza --tree --level=2 --icons=always --color=always --group-directories-first {} | head -80'"
FZF_CTRL_R_COMMAND= _cached_init fzf fzf --zsh

# Tab completion in a fuzzy menu, with previews
if [[ -r $ZPLUG/fzf-tab/fzf-tab.plugin.zsh ]]; then
  source $ZPLUG/fzf-tab/fzf-tab.plugin.zsh
  zstyle ':fzf-tab:*' switch-group '<' '>'
  zstyle ':fzf-tab:*' fzf-flags --bind=tab:accept
  zstyle ':fzf-tab:*' fzf-pad 4
  zstyle ':fzf-tab:*' fzf-min-height 12
  zstyle ':fzf-tab:complete:(cd|z|ls|eza|ll|la|lt):*' fzf-preview 'eza -1 --icons=always --color=always --group-directories-first $realpath 2>/dev/null'
  zstyle ':fzf-tab:complete:(bat|cat|nano|nvim|code|less):*' fzf-preview '[[ -d $realpath ]] && eza -1 --icons=always --color=always $realpath || bat --color=always --style=plain --line-range=:120 $realpath 2>/dev/null'
  zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
  zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap
  zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word 2>/dev/null'
  zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word}'
  zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff --color=always -- $word 2>/dev/null | delta 2>/dev/null'
  zstyle ':fzf-tab:complete:git-(log|checkout|switch|show):*' fzf-preview 'git log --color=always --oneline -n 25 $word 2>/dev/null'
  zstyle ':fzf-tab:complete:*:options' fzf-preview
  zstyle ':fzf-tab:complete:*:argument-1' fzf-preview
fi

# brackets and quotes close themselves
[[ -r $ZPLUG/zsh-autopair/autopair.zsh ]] && source $ZPLUG/zsh-autopair/autopair.zsh     # initialises itself

# cd that learns: `cd proj` jumps to the directory you use most that matches; `cdi` picks from a list
# (the check is silenced because tools that copy this shell's functions without its hooks, such as
# Claude Code, would otherwise print zoxide's "configuration issue" notice before every command)
export _ZO_DOCTOR=0
_cached_init zoxide zoxide init zsh --cmd cd

# Ctrl+R: searchable history with directory, exit status and duration (local only, nothing synced)
if _cached_init atuin atuin init zsh --disable-up-arrow; then
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  # atuin records commands through its background daemon (~/.config/atuin/config.toml). Bring it
  # up now if it is not running, so the first command after a boot does not wait for it.
  [[ -S ${TMPDIR:-/tmp}/atuin-$UID/atuin.sock ]] || atuin daemon start --daemonize &>/dev/null &!
fi

# ---- aliases and small functions ----------------------------------------------------------------
if (( $+commands[eza] )); then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -l --icons=auto --group-directories-first --git --time-style=relative'
  alias la='eza -la --icons=auto --group-directories-first --git --time-style=relative'
  alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
  alias l.='eza -d --icons=auto .*(N)'
else
  alias ls='ls --color=auto' ll='ls -lh' la='ls -lAh' l.='ls -d .*'
fi
(( $+commands[bat] )) && alias cat='bat --paging=never --style=plain'
alias grep='grep --color=auto' egrep='grep -E --color=auto' fgrep='grep -F --color=auto'
# typed searches only (an alias, so scripts and other tools that run rg are not affected)
alias rg="rg --smart-case --colors=path:fg:124,183,255 --colors=line:fg:92,103,115 --colors=match:fg:79,209,197 --colors=match:style:bold"
alias lg='lazygit'
alias lzd='lazydocker'
alias ff='fastfetch'
alias open='xdg-open'
alias update='sudo dnf upgrade --refresh -y && flatpak update -y && mise upgrade && tldr --update'
if [[ $TERM == xterm-kitty ]]; then
  alias icat='kitten icat'                      # show an image in the terminal
  alias ssh='kitten ssh'                        # takes the terminal definition along to the server
fi

mkcd() { mkdir -p -- "$1" && builtin cd -- "$1" }

# y: file manager; leaving it with q puts the shell in the directory you ended up in
y() {
  local tmp=$(mktemp -t yazi-cwd.XXXXXX) cwd
  yazi "$@" --cwd-file=$tmp
  IFS= read -r -d '' cwd < $tmp
  [[ -n $cwd && $cwd != $PWD ]] && builtin cd -- $cwd
  rm -f -- $tmp
}

# p: jump to a project (Alt+P). Lists ~/Documents/Projects by most recent work.
p() {
  local root=$HOME/Documents/Projects dir
  dir=$(command ls -1dt $root/*(/N) 2>/dev/null | sed "s|^$root/||" | fzf --query=${1:-} --select-1 \
        --header='project' --preview "git -C $root/{} -c color.status=always status -sb 2>/dev/null | head -20; echo; eza -1 --icons=always --color=always --group-directories-first $root/{} | head -30") || return
  builtin cd -- $root/$dir
}
_p_widget() { zle push-line; BUFFER='p'; zle accept-line }
zle -N _p_widget
bindkey '\ep' _p_widget

keys() { if (( $+commands[glow] )); then glow $HOME/.config/zsh/keys.md; else command cat $HOME/.config/zsh/keys.md; fi }

# ---- prompt -------------------------------------------------------------------------------------
[[ -r $ZPLUG/powerlevel10k/powerlevel10k.zsh-theme ]] && source $ZPLUG/powerlevel10k/powerlevel10k.zsh-theme
[[ -r $HOME/.config/zsh/p10k.zsh ]] && source $HOME/.config/zsh/p10k.zsh

# ---- suggestions and syntax colours (Summit palette) ------------------------------------------------
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#5c6773'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=60
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
: ${ZSH_AUTOSUGGEST_STRATEGY:=history completion}
[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^ ' autosuggest-accept                 # Ctrl+Space accepts the grey suggestion

typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_HIGHLIGHT_MAXLENGTH=400
ZSH_HIGHLIGHT_STYLES[command]='fg=#4fd1c5'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#4fd1c5'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#4fd1c5'
ZSH_HIGHLIGHT_STYLES[function]='fg=#7cb7ff'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#4fd1c5,italic'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#b9a3f5'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f47067'
ZSH_HIGHLIGHT_STYLES[path]='fg=#dce3ea,underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#84cc6a'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#84cc6a'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#84cc6a'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#e3b341'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#e3b341'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#b9a3f5'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#b9a3f5'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#b9a3f5'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#5c6773'
# must stay last
[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
