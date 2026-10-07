# ~/.config/zsh/welcome.zsh — the card a new kitty window opens with: the current wallpaper, a
# greeting, the three projects you worked on last (type 1, 2 or 3 to go there) and a tip.
#
#   welcome            show it again
#   welcome off | on   stop showing it in new windows, or start again
#
# Everything is read with zsh builtins: no program is started, so it adds about two milliseconds.
# Sourced at the very top of ~/.zshrc, above the instant prompt (output is only allowed there).
# The picture is ~/.cache/summit/welcome.png, redrawn by `wall` whenever the wallpaper changes.

_welcome() {
  emulate -L zsh -o extended_glob
  zmodload zsh/datetime 2>/dev/null
  zmodload -F zsh/stat b:zstat 2>/dev/null

  local rs=$'\e[0m' hi=$'\e[1;38;2;240;244;248m' tx=$'\e[38;2;220;227;234m' mu=$'\e[38;2;134;147;161m'
  local dim=$'\e[38;2;92;103;115m' teal=$'\e[38;2;79;209;197m' purple=$'\e[38;2;185;163;245m'
  local amber=$'\e[38;2;227;179;65m'
  # Nerd Font glyphs, written as escapes because private-use characters do not survive every editor
  local g_branch=$'\ue0a0' g_tip=$'\U000f0335' cap_l=$'\ue0b6' cap_r=$'\ue0b4'
  local -i now=$EPOCHSECONDS i

  # the picture is eight rows tall and takes the left 35 columns when it can be shown
  local img=${XDG_CACHE_HOME:-$HOME/.cache}/summit/welcome.png show=
  local -i off=2
  [[ $TERM == xterm-kitty && -r $img && -r $img.kitty ]] && show=$(<$img.kitty) && off=37
  local -i width=$(( COLUMNS - off - 1 ))

  # ---- greeting and date -------------------------------------------------------------------
  local h date greet
  strftime -s h %H $now; strftime -s date '%A %-d %B' $now
  if (( 10#$h >= 5 && 10#$h < 12 )); then greet='Good morning'
  elif (( 10#$h >= 12 && 10#$h < 17 )); then greet='Good afternoon'
  else greet='Good evening'; fi

  # ---- Claude usage, when it fits on the date line. (No battery here on purpose: reading it makes
  # the kernel ask the laptop's controller, which takes 6 to 13 ms and now and then far longer.) ----
  local info="$mu$date$rs" sep="  ${dim}·${rs}  "
  local -i used=$#date
  local usage=${XDG_CACHE_HOME:-$HOME/.cache}/summit/claude-usage.json json u=
  if [[ -r $usage ]] && json=$(<$usage) && [[ $json == (#b)*'"five_hour":{"used":'([0-9.]##)',"resets_at":'([0-9]##)'},"seven_day":{"used":'([0-9.]##)',"resets_at":'([0-9]##)'}'* ]]; then
    (( now < match[2] )) && u="${match[1]%.*}% of 5 h"
    (( now < match[4] )) && u+="${u:+, }${match[3]%.*}% of week"
    [[ -n $u ]] && (( used + 12 + $#u <= width )) && info+="$sep${mu}Claude $u$rs"
  fi

  # ---- the three most recently touched projects ----------------------------------------------
  local root=$HOME/Documents/Projects d g line c head age
  local -a st cand names branches ages dirs
  local -i t s
  # "last worked on" is the time of the last git operation: the index is rewritten by add, commit,
  # switch, pull and the rest. One stat per repository; folders without git count by their own date.
  {
    for d in $root/*(N/); do
      g=$d/.git
      if zstat -A st +mtime -- $g/index; then t=$st[1]
      elif [[ -f $g ]] && IFS= read -r line < $g && g=${line#gitdir: } && zstat -A st +mtime -- $g/index; then t=$st[1]   # a linked worktree
      else g=; zstat -A st +mtime -- $d && t=$st[1] || t=0; fi
      cand+=("${(l:12::0:)t}"$'\t'"$g"$'\t'"$d")
    done
  } 2>/dev/null
  for c in ${${(O)cand}[1,3]}; do
    t=${c%%$'\t'*}; c=${c#*$'\t'}; g=${c%%$'\t'*}; d=${c#*$'\t'}
    head=
    [[ -n $g ]] && { IFS= read -r head < $g/HEAD } 2>/dev/null
    [[ $head == 'ref: refs/heads/'* ]] && head=${head#ref: refs/heads/} || head=${head[1,7]}
    s=$(( now - t ))
    if   (( s < 90 ));      then age='just now'
    elif (( s < 3600 ));    then age="$(( s / 60 )) min ago"
    elif (( s < 86400 ));   then age="$(( s / 3600 )) h ago"
    elif (( s < 172800 ));  then age='yesterday'
    elif (( s < 1209600 )); then age="$(( s / 86400 )) days ago"
    elif (( s < 5184000 )); then age="$(( s / 604800 )) weeks ago"
    else age="$(( s / 2592000 )) months ago"; fi
    dirs+=($d) names+=(${d:t}) branches+=("$head") ages+=($age)
  done

  # ---- a tip that fits ------------------------------------------------------------------------
  local -a tips=(
    'type `1`, `2` or `3` and Enter to jump to one of the projects above'
    '`Ctrl+R` searches every command you have run; press it again to narrow to this project'
    '`Alt+P` jumps to a project, and `cd name` to the folder you use most that matches'
    '`Ctrl+T` drops a file path into the command; `Alt+C` goes to a folder'
    '`Tab` opens a menu with previews: type to filter, `Tab` again to accept'
    '`Ctrl+Shift+Enter` splits the window; `Ctrl+Alt+arrows` move between splits'
    '`Ctrl+Shift+M` zooms a split to the whole window, and back'
    '`Esc` `Esc` puts sudo in front of the command'
    '`Ctrl+Shift+G` opens the last command'\''s output in a pager'
    '`Ctrl+Shift+Z` jumps back to the previous prompt'
    '`→` or `Ctrl+Space` accepts the grey suggestion'
    '`y` opens the file manager; leave with `q` to stay in the folder you browsed to'
    '`lg` is git in full screen, and `git diff` is syntax-coloured'
    '`tldr tar` shows short examples for a command'
    '`wall next` changes the wallpaper, and the picture on this card with it'
    '`keys` shows every shortcut on one page'
  )
  local tip=
  for i in {1..6}; do
    tip=$tips[$(( RANDOM % $#tips + 1 ))]
    (( ${#${tip//\`/}} + 2 <= width )) && break
    tip=
  done

  # ---- eight lines: greeting, date, a gap, three projects, a gap, the tip -----------------------
  local -a rows
  local -i wn=0 wb=0
  for i in {1..$#names}; do
    (( $#names[i] > wn )) && wn=$#names[i]
    (( $#branches[i] > wb )) && wb=$#branches[i]
  done
  (( wn > 24 )) && wn=24
  (( wb > 18 )) && wb=18
  local key_cap=$'\e[38;2;34;63;68m' key_face=$'\e[1;38;2;129;230;217;48;2;34;63;68m' name=$'\e[1;38;2;79;209;197m'
  rows+=("$hi$greet, $name${(C)USER}$rs" "$info" '')
  for i in {1..$#names}; do
    line="$key_cap$cap_l$key_face$i$rs$key_cap$cap_r$rs  $tx${(r:$wn:)${names[i][1,$wn]}}$rs"
    if (( wb )); then
      if [[ -n $branches[i] ]]; then line+="   $purple$g_branch ${(r:$wb:)${branches[i][1,$wb]}}$rs"
      else line+="     ${(l:$wb:)}"; fi
    fi
    rows+=("$line   $dim$ages[i]$rs")
    functions[$i]="builtin cd -- ${(q)dirs[i]}"
  done
  while (( $#rows < 7 )); do rows+=(''); done
  [[ -n $tip ]] && rows+=("$amber$g_tip$rs $mu${tip//(#b)\`([^\`]##)\`/$tx$match[1]$mu}$rs") || rows+=('')

  # kitty reads the picture file itself; `wall` leaves the ready-made instruction next to it
  (( off > 2 )) && print -n -- $'\r \e_Gr='$#rows','$show$'\e\\'
  for line in "${rows[@]}"; do print -r -- $'\r\e['$off'C'$line; done
  print
}

welcome() {
  local flag=$HOME/.config/zsh/welcome.off
  case $1 in
    off) : >| $flag; print 'The welcome card stays hidden in new windows. `welcome on` brings it back.' ;;
    on)  [[ -e $flag ]] && command rm -f -- $flag; _welcome ;;
    *)   _welcome ;;
  esac
}

# shown once, in the first shell of a new kitty window that is large enough for it
if [[ -o interactive && -t 1 && $TERM == xterm-kitty && -z $SUMMIT_WELCOMED && -z $TMUX && -z $SSH_CONNECTION
      && -z ${ZSH_EXECUTION_STRING+x} && ( $KITTY_WINDOW_ID == 1 || -n $SUMMIT_WELCOME )
      && ! -e $HOME/.config/zsh/welcome.off ]] && (( LINES >= 24 && COLUMNS >= 96 )); then
  _welcome
fi
export SUMMIT_WELCOMED=1
