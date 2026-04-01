#!/bin/bash
  # Claude Code status line command                                                                                                                                                                                                                                         
  input=$(cat)                                                                                                                                                                                                                                                              
                                                                                                                                                                                                                                                                            
  cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')                                                                                                                                                                                                    
  model=$(echo "$input" | jq -r '.model.display_name // empty')                                       
  used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')                                                                                                                                                                                                  
  five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')                                                                                                                                                                                         
  five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.reset_at // empty')                                                                                                                                                                                          
  week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')                                                                                                                                                                                           
  week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.reset_at // empty')                                                                                                                                                                                            
                                                                                                      
  # Working directory (show last 2 path segments)                                                                                                                                                                                                                           
  dir_display=$(echo "$cwd" | awk -F'/' '{if(NF>=2) print $(NF-1)"/"$NF; else print $NF}')            
                                                                                                                                                                                                                                                                            
  # Git branch (skip optional locks to avoid interference)                                            
  branch=$(git -C "${cwd}" branch --show-current 2>/dev/null)                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                            
  parts=""
                                                                                                                                                                                                                                                                            
  # Directory                                                                                         
  [ -n "$dir_display" ] && parts="${dir_display}"

  # Git branch
  [ -n "$branch" ] && parts="${parts}  (${branch})"

  # Model
  [ -n "$model" ] && parts="${parts}  ${model}"
                                                                                                                                                                                                                                                                            
  # Context usage
  if [ -n "$used" ]; then                                                                                                                                                                                                                                                   
    used_int=$(printf "%.0f" "$used")                                                                 
    parts="${parts}  contexts:${used_int}%"
  fi                                                                                                                                                                                                                                                                        
   
  # Build a 10-block visual progress bar for a given percentage                                                                                                                                                                                                             
  make_bar() {                                                                                        
    local pct=$1
    local filled=$(awk "BEGIN{printf \"%.0f\", $pct/10}" 2>/dev/null)
    filled=${filled:-0}                                                                                                                                                                                                                                                     
    local empty=$((10 - filled))
    [ $empty -lt 0 ] && empty=0                                                                                                                                                                                                                                             
    local bar=""                                                                                      
    local i
    for i in $(seq 1 $filled); do bar="${bar}█"; done
    for i in $(seq 1 $empty);  do bar="${bar}░"; done                                                                                                                                                                                                                       
    printf "%s" "$bar"
  }                                                                                                                                                                                                                                                                         
                                                                                                      
  # Rate limits
  rate=""
  if [ -n "$five_h" ]; then                                                                                                                                                                                                                                                 
    five_int=$(awk "BEGIN{printf \"%.0f\", $five_h}" 2>/dev/null)
    five_bar=$(make_bar "$five_h")                                                                                                                                                                                                                                          
    five_label="5h [${five_bar}] ${five_int}%"                                                                                                                                                                                                                              
    if [ -n "$five_h_reset" ]; then
      five_reset_local=$(date -d "$five_h_reset" "+%H:%M" 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$five_h_reset" "+%H:%M" 2>/dev/null)                                                                                                                              
      [ -n "$five_reset_local" ] && five_label="${five_label}(→${five_reset_local})"                                                                                                                                                                                        
    fi                                                                                                                                                                                                                                                                      
    rate="$five_label"                                                                                                                                                                                                                                                      
  fi                                                                                                                                                                                                                                                                        
  if [ -n "$week" ]; then                                                                             
    week_int=$(awk "BEGIN{printf \"%.0f\", $week}" 2>/dev/null)
    week_bar=$(make_bar "$week")                                                                                                                                                                                                                                            
    week_label="7d [${week_bar}] ${week_int}%"
    if [ -n "$week_reset" ]; then                                                                                                                                                                                                                                           
      week_reset_local=$(date -d "$week_reset" "+%m/%d %H:%M" 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$week_reset" "+%m/%d %H:%M" 2>/dev/null)
      [ -n "$week_reset_local" ] && week_label="${week_label}(→${week_reset_local})"                                                                                                                                                                                        
    fi                                                                                                                                                                                                                                                                      
    rate="${rate:+$rate  }$week_label"                                                                                                                                                                                                                                      
  fi                                                                                                                                                                                                                                                                        
  [ -n "$rate" ] && parts="${parts}  ${rate}"                                                         
       
  printf "%s" "$parts"   
