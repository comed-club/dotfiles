#!/usr/bin/env bash
# GitHub Codespaces の使用量を表示する。  使い方: cs-usage.sh [年] [月]
set -euo pipefail
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/cs-usage-lib.sh"

if ! cs_token >/dev/null; then
  echo "エラー: トークンがありません（GH_BILLING_TOKEN / ~/.gh_billing_token）" >&2
  exit 1
fi

YEAR="${1:-$(date +%Y)}"
MONTH="${2:-$(date +%-m)}"
BODY="$(cs_fetch "$YEAR" "$MONTH")"

if ! printf '%s' "$BODY" | jq -e '.usageItems' >/dev/null 2>&1; then
  echo "APIエラー:" >&2; printf '%s\n' "$BODY" >&2; exit 1
fi

echo "=== ${YEAR}年${MONTH}月 Codespaces 内訳（SKU別） ==="
printf '%s' "$BODY" | jq -r '
  [.usageItems[] | select(.product | ascii_downcase | test("codespace"))]
  | group_by(.sku)
  | map({sku: .[0].sku, unit: .[0].unitType,
         qty: (map(.quantity)|add), gross: (map(.grossAmount)|add), net: (map(.netAmount)|add)})
  | (["SKU","UNIT","QTY","GROSS($)","NET($)"],
     (.[] | [.sku, .unit, (.qty|tostring), (.gross|tostring), (.net|tostring)]))
  | @tsv' | column -t -s $'\t'

# 当月なら今日まで、過去月なら満了として按分する
NOW_Y=$(date +%Y); NOW_M=$(date +%-m)
DIM=$(date -d "${YEAR}-${MONTH}-01 +1 month -1 day" +%-d)
if [ "$YEAR" = "$NOW_Y" ] && [ "$MONTH" = "$NOW_M" ]; then ELAPSED=$(date +%-d); else ELAPSED=$DIM; fi

echo
echo "=== 無料枠（Free: compute 120 core-hours / storage 15 GB-month） ==="
printf '%s' "$BODY" | jq -r "$CS_JQ" | awk -F'\t' -v dim="$DIM" -v el="$ELAPSED" '{
    core=$1; stor=$2; net=$3; frac=el/dim;
    printf "compute : %.2f / 120 core-hours   残り %.2f\n", core, 120-core;
    printf "storage : %.2f / 15 GB-month      残り %.2f\n", stor, 15-stor;
    printf "課金額  : $%s   ※0なら無料枠内\n\n", net;
    printf "月末予測（%d/%d日経過ペース）: compute %.1f core-hours   storage %.1f GB-month\n",
           el, dim, core/frac, stor/frac;
  }'
