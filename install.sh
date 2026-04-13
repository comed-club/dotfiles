#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Claude Code のインストール
if ! command -v claude &>/dev/null; then
  echo "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
fi

# ~/.claude/ ディレクトリの作成
mkdir -p ~/.claude

# ステータスラインスクリプトの配置
cp "$SCRIPT_DIR/statusline-command.sh" ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh

# CLAUDE.md の配置（トークン節約ルール）
cp "$SCRIPT_DIR/CLAUDE.md" ~/.claude/CLAUDE.md

# グローバル settings.json を設定
SETTINGS=~/.claude/settings.json
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

tmp=$(mktemp)

# statusLine の設定（bash 経由で実行するよう修正）
if ! grep -q '"statusLine"' "$SETTINGS"; then
  jq '. + {"statusLine": {"type": "command", "command": "bash ~/.claude/statusline-command.sh"}}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
fi

# デフォルトモデルを sonnet に設定                                                                                                                                                                                                                                        
if ! grep -q '"model"' "$SETTINGS"; then
  jq '. + {"model": "sonnet"}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"                                                                                                                                                                                              
fi                                                                                                                                                                                                                                                                        
                                         
# Edit/Write 後の通知フックを追加                                                                                                                                                                                                                                         
if ! grep -q '"PostToolUse"' "$SETTINGS"; then                  
  jq '. + {"hooks": {"PostToolUse": [{"matcher": "Edit|Write", "hooks": [{"type": "command", "command": "echo \"[Hook] ファイルが編集されました: $(date)\""}]}]}}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"                                                          
fi                                                                                                                                                                                                                                                                        
                                         
echo "Claude Code 設定を適用しました。"
