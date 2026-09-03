#!/bin/bash
# Claude Code status line
#   1行目: ディレクトリ / ブランチ / モデル / コンテキスト使用率
#   2行目: 5hレート / 7dレート / Codespaces無料枠
input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.reset_at // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.reset_at // empty')

# 10ブロックのバーを組み立てる
make_bar() {
  local pct=$1
  local filled empty bar="" i
  filled=$(awk "BEGIN{p=$pct/10; if(p<0)p=0; if(p>10)p=10; printf \"%.0f\", p}" 2>/dev/null)
  filled=${filled:-0}
  empty=$((10 - filled))
  [ $empty -lt 0 ] && empty=0
  for i in $(seq 1 $filled); do bar="${bar}█"; done
  for i in $(seq 1 $empty);  do bar="${bar}░"; done
  printf "%s" "$bar"
}

# ---------- 1行目 ----------
dir_display=$(echo "$cwd" | awk -F'/' '{if(NF>=2) print $(NF-1)"/"$NF; else print $NF}')
branch=$(git -C "${cwd}" branch --show-current 2>/dev/null)

line1=""
[ -n "$dir_display" ] && line1="${dir_display}"
[ -n "$branch" ] && line1="${line1}  (${branch})"
[ -n "$model" ] && line1="${line1}  ${model}"
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  line1="${line1}  contexts:${used_int}%"
fi

# ---------- 2行目 ----------
line2=""

if [ -n "$five_h" ]; then
  five_int=$(awk "BEGIN{printf \"%.0f\", $five_h}" 2>/dev/null)
  five_label="5h [$(make_bar "$five_h")] ${five_int}%"
  if [ -n "$five_h_reset" ]; then
    five_reset_local=$(date -d "$five_h_reset" "+%H:%M" 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$five_h_reset" "+%H:%M" 2>/dev/null)
    [ -n "$five_reset_local" ] && five_label="${five_label}(→${five_reset_local})"
  fi
  line2="$five_label"
fi

if [ -n "$week" ]; then
  week_int=$(awk "BEGIN{printf \"%.0f\", $week}" 2>/dev/null)
  week_label="7d [$(make_bar "$week")] ${week_int}%"
  if [ -n "$week_reset" ]; then
    week_reset_local=$(date -d "$week_reset" "+%m/%d %H:%M" 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$week_reset" "+%m/%d %H:%M" 2>/dev/null)
    [ -n "$week_reset_local" ] && week_label="${week_label}(→${week_reset_local})"
  fi
  line2="${line2:+$line2  }$week_label"
fi

# Codespaces無料枠。キャッシュを読むだけで、API取得は非同期に投げる
cs_refresh=""
for p in "$HOME/.claude/bin/cs-usage-refresh.sh" /workspaces/bin/cs-usage-refresh.sh; do
  [ -x "$p" ] && { cs_refresh="$p"; break; }
done
if [ -n "$cs_refresh" ]; then
  cs_cache="${XDG_CACHE_HOME:-$HOME/.cache}/cs-usage"
  cs_ts=0; cs_core=""; cs_stor=""; cs_net=""; cs_st=""
  [ -f "$cs_cache" ] && IFS=$'\t' read -r cs_ts cs_core cs_stor cs_net cs_st < "$cs_cache"

  # 15分以上古い（またはキャッシュ無し）なら非同期で更新。statuslineは待たない
  if [ $(( $(date +%s) - ${cs_ts:-0} )) -gt 900 ]; then
    setsid "$cs_refresh" >/dev/null 2>&1 </dev/null &
    disown 2>/dev/null
  fi

  if [ -n "$cs_core" ] && [ -n "$cs_stor" ]; then
    c_pct=$(awk "BEGIN{printf \"%.0f\", $cs_core/120*100}" 2>/dev/null)
    s_pct=$(awk "BEGIN{printf \"%.0f\", $cs_stor/15*100}" 2>/dev/null)
    cs_label="cs C[$(make_bar "$c_pct")] ${c_pct}% S[$(make_bar "$s_pct")] ${s_pct}%"
    [ "$cs_st" = "err" ] && cs_label="${cs_label}(!)"
    if awk "BEGIN{exit !($c_pct>=80 || $s_pct>=80)}" 2>/dev/null; then cs_label="${cs_label} ⚠"; fi
    line2="${line2:+$line2  }${cs_label}"
  fi
fi

# ---------- 出力 ----------
if [ -n "$line2" ]; then
  printf "%s\n%s" "$line1" "$line2"
else
  printf "%s" "$line1"
fi
