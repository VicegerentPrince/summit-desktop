#!/bin/bash
# Claude Code status line (Summit colours).
#   model · effort   directory  branch   context bar   5-hour and weekly plan usage
# Claude Code passes session JSON on stdin. Everything shown comes from that JSON, plus the
# git branch. Nothing is fetched from the network and no credentials are read.
#
# Side effect, on purpose: the plan usage figures are saved to ~/.cache/summit/claude-usage.json
# so the desktop "Claude" card can show them.
input=$(cat)

IFS=$'\t' read -r model effort cwd ctx h5 h5r d7 d7r added removed < <(
    jq -r '[
        (.model.display_name // "Claude"),
        (.effort.level // ""),
        (.workspace.current_dir // .cwd // ""),
        ((.context_window.used_percentage // 0) | floor),
        (.rate_limits.five_hour.used_percentage // -1 | floor),
        (.rate_limits.five_hour.resets_at // 0),
        (.rate_limits.seven_day.used_percentage // -1 | floor),
        (.rate_limits.seven_day.resets_at // 0),
        (.cost.total_lines_added // 0),
        (.cost.total_lines_removed // 0)
    ] | map(tostring | if . == "" then "-" else . end) | @tsv' <<<"$input" 2>/dev/null
)
[ -z "${model:-}" ] && model="Claude"
[ "$effort" = "-" ] && effort=""
[ "$cwd" = "-" ] && cwd=""

c() { printf '\033[38;2;%sm' "$1"; }
TEAL=$(c '79;209;197'); BLUE=$(c '124;183;255'); PURPLE=$(c '185;163;245'); GREEN=$(c '132;204;106')
AMBER=$(c '227;179;65'); RED=$(c '244;112;103'); TEXT=$(c '220;227;234'); MUTED=$(c '134;147;161'); DIM=$(c '92;103;115')
R=$'\033[0m'; SEP="${DIM} │ ${R}"

level() {   # colour for a percentage: calm, then amber, then red
    if   [ "$1" -ge 90 ]; then printf '%s' "$RED"
    elif [ "$1" -ge 70 ]; then printf '%s' "$AMBER"
    else printf '%s' "$GREEN"; fi
}
left() {    # time until an epoch second, compact
    local s=$(( $1 - $(date +%s) ))
    [ "$s" -le 0 ] && { printf 'now'; return; }
    if   [ "$s" -ge 86400 ]; then printf '%dd %dh' $((s/86400)) $((s%86400/3600))
    elif [ "$s" -ge 3600 ];  then printf '%dh %02dm' $((s/3600)) $((s%3600/60))
    else printf '%dm' $((s/60)); fi
}

out="${TEAL}${model}${R}"
[ -n "$effort" ] && out+="${DIM} · ${R}${MUTED}${effort}${R}"

if [ -n "$cwd" ]; then
    dir=${cwd/#$HOME/\~}
    case "$dir" in \~/Documents/Projects/*) dir=${dir#\~/Documents/Projects/} ;; esac
    out+="${SEP}${TEXT}${dir}${R}"
    branch=$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null)
    [ -n "$branch" ] && out+=" ${PURPLE} ${branch}${R}"
fi

if [ "${added:-0}" != "0" ] || [ "${removed:-0}" != "0" ]; then
    out+="${SEP}${GREEN}+${added}${R} ${RED}-${removed}${R}"
fi

# context window: eight-cell bar
ctx=${ctx:-0}; cells=$(( (ctx * 8 + 50) / 100 )); [ "$cells" -gt 8 ] && cells=8
bar=""; for ((i = 0; i < 8; i++)); do [ "$i" -lt "$cells" ] && bar+="▰" || bar+="▱"; done
out+="${SEP}${MUTED}ctx${R} $(level "$ctx")${bar}${R} ${TEXT}${ctx}%${R}"

if [ "${h5:--1}" -ge 0 ] 2>/dev/null; then
    out+="${SEP}${MUTED}5h${R} $(level "$h5")${h5}%${R}"
    [ "${h5r:-0}" -gt 0 ] && out+="${DIM} ↻ $(left "$h5r")${R}"
fi
if [ "${d7:--1}" -ge 0 ] 2>/dev/null; then
    out+="${SEP}${MUTED}week${R} $(level "$d7")${d7}%${R}"
fi
printf '%s\n' "$out"

# hand the plan usage to the desktop card (atomic write; skipped when Claude Code sent none)
if [ "${h5:--1}" -ge 0 ] 2>/dev/null || [ "${d7:--1}" -ge 0 ] 2>/dev/null; then
    d=${XDG_CACHE_HOME:-$HOME/.cache}/summit
    mkdir -p "$d" 2>/dev/null &&
    printf '{"five_hour":{"used":%s,"resets_at":%s},"seven_day":{"used":%s,"resets_at":%s},"updated":%s}\n' \
        "${h5:--1}" "${h5r:-0}" "${d7:--1}" "${d7r:-0}" "$(date +%s)" > "$d/.claude-usage.$$" 2>/dev/null &&
    mv -f "$d/.claude-usage.$$" "$d/claude-usage.json" 2>/dev/null
fi
exit 0
