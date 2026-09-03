# dotfiles

Codespace 作成時に `install.sh` が自動実行され、Claude Code の設定を配置する。

## 配置されるもの

| ファイル | 配置先 | 内容 |
|---|---|---|
| `statusline-command.sh` | `~/.claude/` | 2行ステータスライン（dir/branch/model/context ＋ 5h・7dレート・Codespaces無料枠） |
| `cs-usage-lib.sh` | `~/.claude/bin/` | 以下2本の共通処理（トークン解決・API取得・集計jq） |
| `cs-usage-refresh.sh` | `~/.claude/bin/` | 使用量を取得し `~/.cache/cs-usage` に書く。statuslineが15分ごとに非同期実行 |
| `cs-usage.sh` | `~/.claude/bin/`（`~/.local/bin/cs-usage` にリンク） | 使用量の詳細表示。`cs-usage [年] [月]` |
| `CLAUDE.md` | `~/.claude/` | トークン節約ルール |

## Codespaces 使用量表示のセットアップ

statuslineの `cs C[...]% S[...]%` を出すにはトークンが要る。

1. https://github.com/settings/personal-access-tokens/new で fine-grained PAT を作る
   - Repository access: **Public Repositories (read-only)**
   - Account permissions: **Plan → Read-only**（これだけ）
2. https://github.com/settings/codespaces の *Codespaces secrets* に **`GH_BILLING_TOKEN`** として登録する

トークンが無い環境では `cs` の表示が出ないだけで、statuslineの他の部分は通常どおり動く。

無料枠は GitHub Free の compute 120 core-hours / storage 15 GB-month を分母にしている。
プランを変えたら `statusline-command.sh` と `cs-usage.sh` の `120` / `15` を直す。
