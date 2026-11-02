#!/bin/bash
# Claude Code status line (Summit colours).
#   model · effort   directory  branch   context bar   plan usage (5-hour, if the plan has one, and weekly)
# Claude Code passes session JSON on stdin. Everything shown comes from that JSON, plus the
# git branch. Nothing is fetched from the network and no credentials are read.
#
# Side effect, on purpose: the plan usage figures are saved to ~/.cache/summit/claude-usage.json
# so the desktop "Claude" card can show them. A window the plan does not have is saved as null.
#
# Claude Code leaves a window out for two reasons that look the same: the plan has no such limit
# (a verified Ultra account has no 5-hour limit), or the window has just reset and no new reply has
# come yet. So a missing window stays in the file until this session has had two more replies
# without it. One is not enough, because a reply still arriving when the window reset was started
# under the old window. Sessions share the file and an idle one knows less than a busy one, so:
#   missing   the prompt_cache.requests count at which each session first found the window gone
#   ended     when the last window ended, so a session still holding it cannot bring it back
input=$(cat)
command -v jq >/dev/null || { echo "Summit status line: please install jq"; exit 0; }

store=${XDG_CACHE_HOME:-$HOME/.cache}/summit
old=$store/claude-usage.json
[ -r "$old" ] || old=/dev/null

{
    IFS=$'\t' read -r model effort cwd ctx h5 h5r d7 d7r added removed
    IFS= read -r usage
} < <(
    jq -r --rawfile old "$old" '
        def merged($got; $had; $ended; $missing; $sid; $asked; $replied):
            if ($got.used_percentage // null) != null then
                if ($got.resets_at // 0) <= $ended then {window: null, ended: $ended}
                else {window: {used: ($got.used_percentage | floor), resets_at: ($got.resets_at // 0)}} end
            elif $had == null then {window: null, ended: (if $ended > 0 then $ended else null end)}
            elif $asked == null then
                # Claude Code before 2.1.251 has no request count: give up on the window 5 hours after it ended
                if $replied and now > ($had.resets_at // 0) + 18000 then {window: null, ended: ($had.resets_at // 0)}
                else {window: $had} end
            elif ($missing[$sid] // ($asked + 1)) > $asked then {window: $had, missing: ($missing + {($sid): $asked})}
            elif $asked - $missing[$sid] >= 2 then {window: null, ended: ($had.resets_at // 0)}
            else {window: $had, missing: $missing} end;

        def section($name; $values):
            ($values | with_entries(select(.value != null and .value != {}))) as $kept
            | if $kept == {} then {} else {($name): $kept} end;

        def record($was):
            def saved($key):
                ($was[$key] | if type == "object" and (.used // -1) >= 0 then . else null end) as $had
                | merged(.rate_limits[$key]; $had; ($was.ended[$key] // 0); ($was.missing[$key] // {});
                         (.session_id // "-"); (.prompt_cache.requests // null); (.context_window.current_usage != null));
            saved("five_hour") as $five | saved("seven_day") as $week
            | {five_hour: $five.window, seven_day: $week.window, updated: (now | floor)}
              + section("ended"; {five_hour: $five.ended, seven_day: $week.ended})
              + section("missing"; {five_hour: $five.missing, seven_day: $week.missing});

        ([
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
        ] | map(tostring | if . == "" then "-" else . end) | @tsv),
        (if (.rate_limits.five_hour.used_percentage // .rate_limits.seven_day.used_percentage // null) == null then ""
         else . as $input
              | (try record((try ($old | fromjson) catch null) | if type == "object" then . else {} end)
                 catch ($input | record({}))) | tojson end)
    ' <<<"$input" 2>/dev/null
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
    # with no 5-hour figure beside it the week is the limit to watch, so say when it resets
    [ "${h5:--1}" -lt 0 ] 2>/dev/null && [ "${d7r:-0}" -gt 0 ] && out+="${DIM} ↻ $(left "$d7r")${R}"
fi
printf '%s\n' "$out"

# hand the plan usage to the desktop card (atomic write; skipped when Claude Code sent none)
if [ -n "$usage" ]; then
    mkdir -p "$store" 2>/dev/null &&
    printf '%s\n' "$usage" > "$store/.claude-usage.$$" 2>/dev/null &&
    mv -f "$store/.claude-usage.$$" "$store/claude-usage.json" 2>/dev/null
    # Claude Code cancels a run when the next update arrives, which can strand a temporary file
    for f in "$store"/.claude-usage.*; do
        [ -e "$f" ] && [ "$f" -ot "$store/claude-usage.json" ] && rm -f "$f"
    done
fi
exit 0
