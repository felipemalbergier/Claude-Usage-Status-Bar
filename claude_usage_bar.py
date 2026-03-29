#!/usr/bin/env python3
"""
Claude Code Usage — macOS Menu Bar App
Reads rate limit data from Claude Code's status line output.

Requires: pip install rumps   (one-time, auto-run by launch.sh)
"""

import json
import os
import threading
from datetime import datetime, timezone
from pathlib import Path

try:
    import rumps
except ImportError:
    print("Run:  pip install rumps  then try again.")
    raise SystemExit(1)

# ── Config ────────────────────────────────────────────────────────────────────
STATUSLINE_CACHE = Path("/tmp/claude_statusline_data.json")
REFRESH_SEC      = 10   # how often to re-read the cache file


# ── Helpers ───────────────────────────────────────────────────────────────────

def fmt_cost(c: float) -> str:
    return f"${c:.4f}" if c < 0.01 else f"${c:.2f}"

def fmt_duration(total_s: int) -> str:
    if total_s <= 0:
        return "resetting…"
    h, rem = divmod(total_s, 3600)
    m, _   = divmod(rem, 60)
    if h > 0:  return f"{h}h {m}m"
    if m > 0:  return f"{m}m"
    return f"<1m"

def progress_bar(pct: float, width: int = 20) -> str:
    filled = round(pct / 100 * width)
    filled = max(0, min(width, filled))
    return "█" * filled + "░" * (width - filled)

def short_bar(pct: float, width: int = 10) -> str:
    filled = round(pct / 100 * width)
    filled = max(0, min(width, filled))
    return "█" * filled + "░" * (width - filled)


# ── Read status line data ─────────────────────────────────────────────────────

def read_statusline_data() -> dict | None:
    """Read the JSON written by ~/.claude/statusline.sh."""
    try:
        if STATUSLINE_CACHE.exists():
            text = STATUSLINE_CACHE.read_text().strip()
            if text:
                return json.loads(text)
    except Exception:
        pass
    return None


# ── App ───────────────────────────────────────────────────────────────────────

class ClaudeUsageApp(rumps.App):

    def __init__(self):
        super().__init__(name="Claude Usage", title="⚡ waiting…", quit_button=None)

        # ── Rate limit section ─────────────────────────────────
        self.mi_header      = rumps.MenuItem("⚡  RATE LIMITS")
        self.mi_5h_bar      = rumps.MenuItem("   5h: waiting for data…")
        self.mi_5h_reset    = rumps.MenuItem("   Resets in: —")
        self.mi_7d_bar      = rumps.MenuItem("   7d: —")
        self.mi_7d_reset    = rumps.MenuItem("   Resets in: —")

        # ── Context window section ─────────────────────────────
        self.mi_ctx_header  = rumps.MenuItem("📐  CONTEXT WINDOW")
        self.mi_ctx_bar     = rumps.MenuItem("   —")
        self.mi_ctx_tokens  = rumps.MenuItem("   —")

        # ── Cost section ───────────────────────────────────────
        self.mi_cost_header = rumps.MenuItem("💰  SESSION COST")
        self.mi_cost        = rumps.MenuItem("   —")

        # ── Footer ─────────────────────────────────────────────
        self.mi_model       = rumps.MenuItem("   Model: —")
        self.mi_refresh     = rumps.MenuItem("🔄  Refresh",          callback=self.manual_refresh)
        self.mi_updated     = rumps.MenuItem("   Updated: —")
        self.mi_quit        = rumps.MenuItem("Quit",                  callback=self.quit_app)

        # Disable non-clickable items
        for mi in (self.mi_header, self.mi_5h_bar, self.mi_5h_reset,
                   self.mi_7d_bar, self.mi_7d_reset,
                   self.mi_ctx_header, self.mi_ctx_bar, self.mi_ctx_tokens,
                   self.mi_cost_header, self.mi_cost,
                   self.mi_model, self.mi_updated):
            mi.set_callback(None)

        self.menu = [
            self.mi_header,
            self.mi_5h_bar,
            self.mi_5h_reset,
            self.mi_7d_bar,
            self.mi_7d_reset,
            None,
            self.mi_ctx_header,
            self.mi_ctx_bar,
            self.mi_ctx_tokens,
            None,
            self.mi_cost_header,
            self.mi_cost,
            None,
            self.mi_model,
            self.mi_refresh,
            self.mi_updated,
            None,
            self.mi_quit,
        ]

        self._refresh_display()
        self._schedule()

    # ── Scheduling ────────────────────────────────────────────────────────────

    def _schedule(self):
        t = threading.Timer(REFRESH_SEC, self._tick)
        t.daemon = True
        t.start()

    def _tick(self):
        self._refresh_display()
        self._schedule()

    def manual_refresh(self, _=None):
        self.title = "⚡ …"
        self._refresh_display()

    # ── Main display refresh ──────────────────────────────────────────────────

    def _refresh_display(self):
        now_str = datetime.now().strftime("%H:%M:%S")
        data = read_statusline_data()

        if not data:
            self.title = "⚡ no data"
            self.mi_5h_bar.title  = "   Use Claude Code to generate data"
            self.mi_updated.title = f"   Updated: {now_str}"
            return

        now_utc = datetime.now(timezone.utc)
        rl = data.get("rate_limits") or {}

        # ── 5-hour window ─────────────────────────────────────
        five_h = rl.get("five_hour") or {}
        pct_5h = five_h.get("used_percentage")
        reset_5h = five_h.get("resets_at")

        if pct_5h is not None:
            bar_5h = progress_bar(pct_5h)
            self.mi_5h_bar.title = f"   5h: {bar_5h}  {pct_5h:.0f}%"

            if reset_5h:
                reset_dt = datetime.fromtimestamp(reset_5h, tz=timezone.utc)
                secs_left = max(0, int((reset_dt - now_utc).total_seconds()))
                time_str = fmt_duration(secs_left)
                reset_local = reset_dt.astimezone().strftime("%H:%M")
                self.mi_5h_reset.title = f"   Resets in {time_str} ({reset_local})"
            else:
                self.mi_5h_reset.title = "   Resets in: —"

            # Status bar: show 5h usage prominently
            self.title = f"⚡ {short_bar(pct_5h)} {pct_5h:.0f}%  ⏱ {time_str if reset_5h else '—'}"
        else:
            self.mi_5h_bar.title   = "   5h: no data yet"
            self.mi_5h_reset.title = ""
            self.title = "⚡ waiting…"

        # ── 7-day window ──────────────────────────────────────
        seven_d = rl.get("seven_day") or {}
        pct_7d = seven_d.get("used_percentage")
        reset_7d = seven_d.get("resets_at")

        if pct_7d is not None:
            bar_7d = progress_bar(pct_7d)
            self.mi_7d_bar.title = f"   7d: {bar_7d}  {pct_7d:.0f}%"

            if reset_7d:
                reset_dt = datetime.fromtimestamp(reset_7d, tz=timezone.utc)
                secs_left = max(0, int((reset_dt - now_utc).total_seconds()))
                time_str_7d = fmt_duration(secs_left)
                reset_local = reset_dt.astimezone().strftime("%a %H:%M")
                self.mi_7d_reset.title = f"   Resets in {time_str_7d} ({reset_local})"
            else:
                self.mi_7d_reset.title = ""
        else:
            self.mi_7d_bar.title   = "   7d: no data yet"
            self.mi_7d_reset.title = ""

        # ── Context window ────────────────────────────────────
        ctx = data.get("context_window") or {}
        ctx_pct = ctx.get("used_percentage")
        if ctx_pct is not None:
            ctx_bar = progress_bar(ctx_pct)
            self.mi_ctx_bar.title = f"   {ctx_bar}  {ctx_pct:.0f}% used"
            inp = ctx.get("total_input_tokens", 0)
            out = ctx.get("total_output_tokens", 0)
            win = ctx.get("context_window_size", 0)
            if win:
                self.mi_ctx_tokens.title = f"   {inp+out:,} / {win:,} tokens"
            else:
                self.mi_ctx_tokens.title = ""
        else:
            self.mi_ctx_bar.title    = "   —"
            self.mi_ctx_tokens.title = ""

        # ── Cost ──────────────────────────────────────────────
        cost_data = data.get("cost") or {}
        total_cost = cost_data.get("total_cost_usd")
        if total_cost is not None:
            self.mi_cost.title = f"   {fmt_cost(total_cost)}"
        else:
            self.mi_cost.title = "   —"

        # ── Model ─────────────────────────────────────────────
        model = data.get("model") or {}
        model_name = model.get("display_name") or model.get("id") or "—"
        self.mi_model.title = f"   Model: {model_name}"

        self.mi_updated.title = f"   Updated: {now_str}"

    # ── Actions ───────────────────────────────────────────────────────────────

    def quit_app(self, _):
        rumps.quit_application()


if __name__ == "__main__":
    ClaudeUsageApp().run()
