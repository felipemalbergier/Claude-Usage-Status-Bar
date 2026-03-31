#!/bin/bash
# Claude Code Status Line — writes rate limit data for menu bar app
# Also outputs a status line for Claude Code's terminal display
input=$(cat)

# Write full JSON to cache file for the menu bar app
echo "$input" > /tmp/claude_statusline_data.json

# Output a compact status line for the terminal
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

RESET_STR=""
if [ -n "$FIVE_H_RESET" ]; then
  NOW=$(date +%s)
  SECS_LEFT=$(( FIVE_H_RESET - NOW ))
  if [ "$SECS_LEFT" -le 0 ]; then
    RESET_STR="resetting…"
  else
    HRS=$(( SECS_LEFT / 3600 ))
    MINS=$(( (SECS_LEFT % 3600) / 60 ))
    if [ "$HRS" -gt 0 ]; then
      RESET_STR="resets ${HRS}h ${MINS}m"
    else
      RESET_STR="resets ${MINS}m"
    fi
  fi
fi

LIMITS=""
[ -n "$FIVE_H" ] && LIMITS="5h: $(printf '%.0f' "$FIVE_H")%"
[ -n "$RESET_STR" ] && LIMITS="${LIMITS:+$LIMITS }($RESET_STR)"
WEEK_RESET_STR=""
if [ -n "$WEEK_RESET" ]; then
  NOW=$(date +%s)
  SECS_LEFT=$(( WEEK_RESET - NOW ))
  if [ "$SECS_LEFT" -le 0 ]; then
    WEEK_RESET_STR="resetting…"
  else
    DAYS=$(( SECS_LEFT / 86400 ))
    HRS=$(( (SECS_LEFT % 86400) / 3600 ))
    if [ "$DAYS" -gt 0 ]; then
      WEEK_RESET_STR="resets ${DAYS}d ${HRS}h"
    else
      MINS=$(( (SECS_LEFT % 3600) / 60 ))
      WEEK_RESET_STR="resets ${HRS}h ${MINS}m"
    fi
  fi
fi

[ -n "$WEEK" ] && LIMITS="${LIMITS:+$LIMITS  }7d: $(printf '%.0f' "$WEEK")%"
[ -n "$WEEK_RESET_STR" ] && LIMITS="${LIMITS:+$LIMITS }($WEEK_RESET_STR)"

TS=$(date +"%H:%M:%S")
[ -n "$LIMITS" ] && echo "$TS [$MODEL] $LIMITS" || echo "$TS [$MODEL]"
