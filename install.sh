#!/bin/bash                                                                                                                                                                                                                                                               
       
  # Claude Code のインストール                                                                                                                                                                                                                                              
  if ! command -v claude &>/dev/null; then                                                            
    echo "Installing Claude Code..."                                                                                                                                                                                                                                        
    npm install -g @anthropic-ai/claude-code
  fi                                                                                                                                                                                                                                                                        
                                                                                                      
  # ステータスラインスクリプトの配置                                                                                                                                                                                                                                        
  mkdir -p ~/.claude                                                                                  
  cp "$(dirname "$0")/statusline-command.sh" ~/.claude/statusline-command.sh                                                                                                                                                                                                
  chmod +x ~/.claude/statusline-command.sh
                                                                                                                                                                                                                                                                            
  # グローバル settings.json にステータスライン設定を追加                                                                                                                                                                                                                   
  SETTINGS=~/.claude/settings.json                                                                                                                                                                                                                                          
  if [ ! -f "$SETTINGS" ]; then                                                                                                                                                                                                                                             
    echo '{}' > "$SETTINGS"                                                                                                                                                                                                                                                 
  fi   
                                                                                                                                                                                                                                                                            
  # statusLine がまだ設定されていない場合のみ追記                                                                                                                                                                                                                           
  if ! grep -q '"statusLine"' "$SETTINGS"; then
    # {} を置き換えてstatusLine を追加                                                                                                                                                                                                                                      
    tmp=$(mktemp)                                                                                                                                                                                                                                                           
    jq '. + {"statusLine": {"type": "command", "command": "~/.claude/statusline-command.sh"}}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"                                                                                                                                
  fi                                                                                                                                                                                                                                                                        
                                                                                                      
  echo "Claude Code statusline configured."    
