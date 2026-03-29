# Claude Usage Status Bar

A lightweight macOS menu bar app that displays real-time Claude Code usage metrics including rate limits, context window usage, and session costs.

## Features

- **Rate Limit Monitoring**: Track 5-hour and 7-day rate limit usage with visual progress bars
- **Context Window Usage**: See current context window utilization
- **Session Costs**: Display total session cost in USD
- **Auto-Refresh**: Updates every 10 seconds (configurable)
- **Menu Bar Integration**: Sleek macOS menu bar app using `rumps`

## Requirements

- macOS (10.13+)
- Python 3.7+
- `rumps` library (installed automatically by launch script)

## Installation

```bash
git clone https://github.com/felipem/Claude-Usage-Status-Bar.git
cd Claude-Usage-Status-Bar
```

## Usage

Run the launch script:

```bash
./launch.sh
```

The app will:
1. Install dependencies (if needed)
2. Kill any existing instances
3. Launch the menu bar app
4. Display logs at `/tmp/claude_usage_bar.log`

Look for the ⚡ icon in your macOS menu bar!

## Configuration

Edit `claude_usage_bar.py` to customize:

```python
STATUSLINE_CACHE = Path("/tmp/claude_statusline_data.json")  # Data source
REFRESH_SEC = 10  # Refresh interval in seconds
```

## How It Works

The app reads rate limit data from Claude Code's status line output (stored in `/tmp/claude_statusline_data.json`). Make sure Claude Code is running and has the status line feature enabled.

## License

MIT
