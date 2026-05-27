#!/bin/bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r 'if .context_window.used_percentage != null then (.context_window.used_percentage | round | tostring) + "%" else "-" end')
usage_5h=$(echo "$input" | jq -r 'if (.rate_limits.five_hour.used_percentage // null) != null then "5h: " + (.rate_limits.five_hour.used_percentage | round | tostring) + "%" else "" end')
usage_7d=$(echo "$input" | jq -r 'if (.rate_limits.seven_day.used_percentage // null) != null then "7d: " + (.rate_limits.seven_day.used_percentage | round | tostring) + "%" else "" end')

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
