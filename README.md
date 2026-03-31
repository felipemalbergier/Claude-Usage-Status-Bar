# Claude Usage Status Bar

A lightweight macOS menu bar app that displays real-time Claude Code usage metrics including rate limits, context window usage, and session costs. Also includes a Claude Code status line script that shows usage directly in the Claude terminal window.

## Features

- **Rate Limit Monitoring**: Track 5-hour and 7-day rate limit usage with visual progress bars and time until reset
- **Context Window Usage**: See current context window utilization
- **Session Costs**: Display total session cost in USD
- **Auto-Refresh**: Updates every 10 seconds (configurable)
- **Menu Bar Integration**: Sleek macOS menu bar app using `rumps`
- **Claude Terminal Status Line**: Shows a compact usage summary directly in the Claude Code window

## Requirements

- macOS (10.13+)
- Python 3.7+
- `rumps` library (installed automatically by launch script)
- `jq` (for the status line script — install via `brew install jq`)

## How It Works

```
Claude Code → statusline.sh → /tmp/claude_statusline_data.json → claude_usage_bar.py → ⚡ menu bar
```

Claude Code calls `statusline.sh` on every update, passing usage data as JSON via stdin. The script:
1. Writes the full JSON to `/tmp/claude_statusline_data.json` (read by the menu bar app)
2. Outputs a compact status line that Claude Code displays in its terminal window

## Installation

```bash
git clone https://github.com/felipemalbergier/Claude-Usage-Status-Bar.git
cd Claude-Usage-Status-Bar
```

### 1. Set up the Claude Code status line

Copy `statusline.sh` to your Claude config directory and make it executable:

```bash
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Then configure Claude Code to use it by adding to `~/.claude/settings.json`:

```json
{
  "statusCommand": "~/.claude/statusline.sh"
}
```

Restart Claude Code. You should see a line like this in your Claude terminal window:

```
11:49:13 [Sonnet 4.6] 5h: 13% (resets 4h 10m)  7d: 62% (resets 1d 1h)
```

### 2. Launch the menu bar app

```bash
./launch.sh
```

The script will:
1. Check Python 3 is available
2. Install `rumps` if needed
3. Kill any existing instance
4. Launch the menu bar app in the background

Look for the ⚡ icon in your macOS menu bar!

## Status Line Output

The status line shows:

| Field | Example | Description |
|---|---|---|
| Timestamp | `11:49:13` | Time of last update |
| Model | `[Sonnet 4.6]` | Current model |
| 5h usage | `5h: 13%` | 5-hour rate limit used |
| 5h reset | `(resets 4h 10m)` | Time until 5h window resets |
| 7d usage | `7d: 62%` | 7-day rate limit used |
| 7d reset | `(resets 1d 1h)` | Time until 7d window resets |

## Configuration

Edit `claude_usage_bar.py` to customize the menu bar app:

```python
STATUSLINE_CACHE = Path("/tmp/claude_statusline_data.json")  # Data source
REFRESH_SEC = 10  # Refresh interval in seconds
```

Edit `statusline.sh` to customize what appears in the Claude terminal window.

## License

MIT
