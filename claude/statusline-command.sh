#!/bin/bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r 'if .context_window.used_percentage != null then (.context_window.used_percentage | round | tostring) + "%" else "-" end')

pct_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
pct_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
reset_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
reset_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

now=$(date +%s)
fmt_reset() {
  local diff=$(( $1 - now ))
  [ "$diff" -le 0 ] && { echo "now"; return; }
  local d=$((diff / 86400))
  local h=$(((diff % 86400) / 3600))
  local m=$(((diff % 3600) / 60))
  if [ "$d" -gt 0 ]; then echo "${d}d${h}h"
  elif [ "$h" -gt 0 ]; then echo "${h}h${m}m"
  else echo "${m}m"
  fi
}

usage_5h=""
if [ -n "$pct_5h" ]; then
  usage_5h="5h: $(printf '%.0f' "$pct_5h")%"
  [ -n "$reset_5h" ] && usage_5h="$usage_5h (resets in $(fmt_reset "$reset_5h"))"
fi
usage_7d=""
if [ -n "$pct_7d" ]; then
  usage_7d="7d: $(printf '%.0f' "$pct_7d")%"
  [ -n "$reset_7d" ] && usage_7d="$usage_7d (resets in $(fmt_reset "$reset_7d"))"
fi

branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)

cwd_display="${cwd/#$HOME/~}"
[ -n "$branch" ] && dir_display="$cwd_display ($branch)" || dir_display="$cwd_display"

usage_str=""
[ -n "$usage_5h" ] && usage_str="$usage_5h"
if [ -n "$usage_7d" ]; then
  [ -n "$usage_str" ] && usage_str="$usage_str | $usage_7d" || usage_str="$usage_7d"
fi

line="$dir_display | $model | ctx: $used_pct"
[ -n "$usage_str" ] && line="$line | usage: $usage_str"

echo "$line"
