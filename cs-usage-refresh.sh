#!/usr/bin/env bash
# Codespaces使用量をAPIから取得し、statusline用キャッシュに書き出す。
# 出力形式: epoch<TAB>core_hours<TAB>gb_month<TAB>net<TAB>status
set -uo pipefail
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/cs-usage-lib.sh"

LOCK="${CS_CACHE}.lock"
mkdir -p "$(dirname "$CS_CACHE")"

# 多重起動の抑止（2分以上前のロックは残骸とみなす）
if [ -d "$LOCK" ]; then
  age=$(( $(date +%s) - $(stat -c %Y "$LOCK" 2>/dev/null || echo 0) ))
  [ "$age" -lt 120 ] && exit 0
  rmdir "$LOCK" 2>/dev/null
fi
mkdir "$LOCK" 2>/dev/null || exit 0
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

if ! cs_token >/dev/null; then
  printf '%s\t\t\t\tnotoken\n' "$(date +%s)" > "$CS_CACHE"
  exit 0
fi

BODY="$(cs_fetch "$(date +%Y)" "$(date +%-m)")" || BODY=""
VALS="$(printf '%s' "$BODY" | jq -r "$CS_JQ" 2>/dev/null)"

if [ -n "$VALS" ]; then
  printf '%s\t%s\tok\n' "$(date +%s)" "$VALS" > "$CS_CACHE"
elif [ -f "$CS_CACHE" ]; then
  # 取得失敗。前回値は残しつつ status だけ err に落とす
  awk -F'\t' -v OFS='\t' '{$5="err"; print}' "$CS_CACHE" > "$CS_CACHE.tmp" && mv "$CS_CACHE.tmp" "$CS_CACHE"
else
  printf '%s\t\t\t\terr\n' "$(date +%s)" > "$CS_CACHE"
fi
