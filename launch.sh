#!/bin/bash
# Claude Code Usage — Menu Bar  •  Launch Script

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$DIR/claude_usage_bar.py"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

echo ""
echo -e "${BOLD}⚡ Claude Code Usage — Menu Bar${NC}"
echo "────────────────────────────────"

# ── 1. macOS check ─────────────────────────────────────────
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo -e "${RED}✗ This app is for macOS only.${NC}"; exit 1
fi

# ── 2. Python 3 ────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  echo -e "${RED}✗ Python 3 not found.${NC}"
  echo "  Install via: brew install python"
  exit 1
fi
echo -e "${GREEN}✓ Python $(python3 --version | cut -d' ' -f2)${NC}"

# ── 3. Install rumps ───────────────────────────────────────
if python3 -c "import rumps" 2>/dev/null; then
  echo -e "${GREEN}✓ rumps already installed${NC}"
else
  echo -e "${YELLOW}⚙  Installing rumps...${NC}"
  pip3 install rumps --quiet 2>/dev/null || pip3 install rumps --quiet --break-system-packages
  echo -e "${GREEN}✓ rumps installed${NC}"
fi

# ── 4. Kill any existing instances ─────────────────────────
KILLED=0
if pgrep -f "claude_usage_bar.py" &>/dev/null; then
  echo -e "${YELLOW}⚠  Found a running instance — stopping it...${NC}"
  pids=$(pgrep -f "claude_usage_bar.py" || true)
  for pid in $pids; do
    path=$(ps -p "$pid" -o args= 2>/dev/null || true)
    echo "   Stopping PID $pid  ($path)"
  done
  pkill -f "claude_usage_bar.py" || true
  sleep 1
  KILLED=1
fi

if [[ $KILLED -eq 0 ]]; then
  echo -e "${GREEN}✓ No existing instance running${NC}"
fi

# ── 5. Launch ──────────────────────────────────────────────
echo ""
echo -e "${GREEN}✓ Launching menu bar app...${NC}"
echo "  Look for ${BOLD}⚡${NC} in your menu bar."
echo "  Close this window whenever you like — the app keeps running."
echo ""

nohup python3 "$APP" > /tmp/claude_usage_bar.log 2>&1 &
echo -e "${BOLD}PID: $!${NC}  •  Logs: /tmp/claude_usage_bar.log"

sleep 2
