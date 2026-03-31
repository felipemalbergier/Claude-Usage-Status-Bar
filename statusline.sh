#!/bin/bash
# Claude Code Status Line — writes rate limit data for menu bar app
# Also outputs a status line for Claude Code's terminal display
input=$(cat)

# Write full JSON to cache file for the menu bar app
echo "$input" > /tmp/claude_statusline_data.json

# Colors
DIM_GRAY='\033[2;37m'
DIM_BLUE='\033[2;36m'
DIM_GREEN='\033[2;32m'
YELLOW='\033[33m'
RED='\033[31m'
NC='\033[0m'

# Pick traffic light color based on usage percentage (dimmed green, full yellow, full red)
traffic_color() {
  local pct=$1
  if [ "$pct" -ge 80 ]; then
    echo "$RED"
  elif [ "$pct" -ge 50 ]; then
    echo "$YELLOW"
  else
    echo "$DIM_GREEN"
  fi
}

# Format seconds left as "Xh Xm left" or "Xd Xh left"
fmt_left() {
  local secs=$1
  local days hrs mins
  if [ "$secs" -le 0 ]; then
    echo "resetting…"
    return
  fi
  days=$(( secs / 86400 ))
  hrs=$(( (secs % 86400) / 3600 ))
  mins=$(( (secs % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    echo "${days}d${hrs}h left"
  elif [ "$hrs" -gt 0 ]; then
    echo "${hrs}h${mins}m left"
  else
    echo "${mins}m left"
  fi
}

# Output a compact status line for the terminal
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
WEEK=$(echo "$input"  | jq -r '.rate_limits.seven_day.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK_RESET=$(echo "$input"   | jq -r '.rate_limits.seven_day.resets_at // empty')
CTX=$(echo "$input"   | jq -r '.context_window.used_percentage // empty')

NOW=$(date +%s)
LIMITS=""

# 5h block
if [ -n "$FIVE_H" ]; then
  PCT5=$(printf '%.0f' "$FIVE_H")
  COLOR5=$(traffic_color "$PCT5")
  LIMITS="${COLOR5}5h: ${PCT5}%${NC}"
  if [ -n "$FIVE_H_RESET" ]; then
    SECS=$(( FIVE_H_RESET - NOW ))
    LIMITS="${LIMITS} ${DIM_GRAY}($(fmt_left "$SECS"))${NC}"
  fi
fi

# 7d block
if [ -n "$WEEK" ]; then
  PCT7=$(printf '%.0f' "$WEEK")
  COLOR7=$(traffic_color "$PCT7")
  LIMITS="${LIMITS:+$LIMITS ${DIM_GRAY}·${NC} }${COLOR7}7d: ${PCT7}%${NC}"
  if [ -n "$WEEK_RESET" ]; then
    SECS=$(( WEEK_RESET - NOW ))
    LIMITS="${LIMITS} ${DIM_GRAY}($(fmt_left "$SECS"))${NC}"
  fi
fi

# context window block
if [ -n "$CTX" ]; then
  PCTC=$(printf '%.0f' "$CTX")
  COLORC=$(traffic_color "$PCTC")
  LIMITS="${LIMITS:+$LIMITS ${DIM_GRAY}·${NC} }${COLORC}ctx: ${PCTC}%${NC}"
fi

TS=$(date +"%H:%M:%S")
if [ -n "$LIMITS" ]; then
  echo -e "${DIM_GRAY}${TS} [${MODEL}]${NC}   ${LIMITS}"
else
  echo -e "${DIM_GRAY}${TS} [${MODEL}]${NC}"
fi
