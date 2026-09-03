#!/usr/bin/env bash
# cs-usage.sh / cs-usage-refresh.sh の共通部分。単体では実行しない。

CS_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cs-usage"

# トークンの解決。Codespaces secret を最優先にする
cs_token() {
  if [ -n "${GH_BILLING_TOKEN:-}" ]; then printf '%s' "$GH_BILLING_TOKEN"; return 0; fi
  local f
  for f in "$HOME/.gh_billing_token" /workspaces/.gh_billing_token; do
    if [ -f "$f" ]; then tr -d '[:space:]' < "$f"; return 0; fi
  done
  return 1
}

# GitHubログイン名の解決。Codespacesでは GITHUB_USER が入っている
cs_login() {
  if [ -n "${GH_BILLING_USER:-}" ]; then printf '%s' "$GH_BILLING_USER"; return 0; fi
  if [ -n "${GITHUB_USER:-}" ];     then printf '%s' "$GITHUB_USER"; return 0; fi
  return 1
}

# 指定月の使用量をJSONで取得
cs_fetch() {
  local year="$1" month="$2" token login
  token="$(cs_token)" || return 1
  login="$(cs_login)" || return 1
  curl -sS --max-time 20 \
    -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/users/${login}/settings/billing/usage?year=${year}&month=${month}"
}

# JSONから core-hours / GB-month / 課金額 をタブ区切りで取り出す
# compute の quantity は実時間なので SKU の "N-core" を掛けて core-hours にする
# storage の unitType は GigabyteHours だが実単位は GB-month（pricePerUnit $0.07 で確認）
CS_JQ='
  [.usageItems[] | select(.product | ascii_downcase | test("codespace"))] as $cs
  | ([$cs[] | select(.unitType | ascii_downcase | test("^hours?$"))
      | .quantity * ((.sku | capture("(?<n>[0-9]+)-core") | .n | tonumber) // 1)] | add // 0) as $core
  | ([$cs[] | select(.unitType | ascii_downcase | test("gigabyte")) | .quantity] | add // 0) as $stor
  | ([$cs[] | .netAmount] | add // 0) as $net
  | "\($core)\t\($stor)\t\($net)"'
