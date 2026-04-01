#!/bin/bash                                                                                         
if ! command -v claude &>/dev/null; then                                                                                                                                                                                                                                  
  echo "Installing Claude Code..."                                                                  
  npm install -g @anthropic-ai/claude-code
fi     
