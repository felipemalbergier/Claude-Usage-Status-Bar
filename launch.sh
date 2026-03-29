#!/bin/bash
# Claude Code Usage — Menu Bar  •  Launch Script
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$DIR/claude_usage_bar.py"

echo "⚡ Claude Code Usage — Menu Bar"
echo "────────────────────────────────"

[[ "$OSTYPE" != "darwin"* ]] && echo "macOS only." && exit 1

if ! python3 -c "import rumps" 2>/dev/null; then
  echo "Installing rumps..."
  pip3 install rumps --quiet 2>/dev/null || pip3 install rumps --quiet --break-system-packages
fi

# Kill any existing instance
pkill -f "claude_usage_bar.py" 2>/dev/null || true
sleep 1

echo "Launching… look for ⚡ in your menu bar."
nohup python3 "$APP" > /tmp/claude_usage_bar.log 2>&1 &
echo "PID: $!  •  Logs: /tmp/claude_usage_bar.log"
sleep 2
