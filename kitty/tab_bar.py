#!/usr/bin/env python3
"""Powerline tabs with background Git status for the focused pane."""

import re
import subprocess
from concurrent.futures import ThreadPoolExecutor
from copy import copy
from random import Random

from kitty.fast_data_types import add_timer, get_boss, wcswidth
from kitty.tab_bar import as_rgb, draw_tab_with_powerline
from kitty.utils import color_as_int


# Fish prompt colors with at least 4.5:1 contrast against white text.
_TAB_BACKGROUNDS = tuple(int(color, 16) for color in """
d81b60 c2185b ad1457 880e4f c51162 ab47bc 9c27b0 8e24aa 7b1fa2 6a1b9a 4a148c aa00ff
7e57c2 673ab7 5e35b1 512da8 4527a0 311b92 7c4dff 651fff 6200ea 5c6bc0 3f51b5 3949ab
303f9f 283593 1a237e 3d5afe 304ffe 1976d2 1565c0 0d47a1 2962ff 0277bd 01579b 00838f
006064 00796b 00695c 004d40 827717 bf360c dd2c00 8d6e63 795548 6d4c41 5d4037 4e342e
3e2723 757575 616161 424242 212121 546e7a 455a64 37474f 263238
""".split())
_tab_backgrounds = {}


def _colored_tab(tab):
    if tab.is_active:
        if tab.tab_id not in _tab_backgrounds:
            boss = get_boss()
            for tab_id in tuple(_tab_backgrounds):
                if boss.tab_for_id(tab_id) is None:
                    del _tab_backgrounds[tab_id]
            used = set(_tab_backgrounds.values())
            available = [color for color in _TAB_BACKGROUNDS if color not in used]
            random = Random(tab.tab_id)
            if available:
                background = random.choice(available)
            else:
                # Keep white text readable even after the palette is exhausted.
                background = random.choice(_TAB_BACKGROUNDS)
                while background in used:
                    background = sum(random.randrange(112) << shift for shift in (16, 8, 0))
            _tab_backgrounds[tab.tab_id] = background
        background = _tab_backgrounds[tab.tab_id]
        return tab._replace(active_bg=background, active_fg=0xFFFFFF)
    return tab._replace(
        inactive_bg=0x303030,
        inactive_fg=0xFFFFFF,
    )




_BRANCH_COLOR = 0xBB9AF7
_STATUS_COLORS = {
    "⬆": 0x7AA2F7,
    "⬇": 0x7AA2F7,
    "✭": 0xBB9AF7,
    "✚": 0x9ECE6A,
    "✖": 0xF7768E,
    "✱": 0xE0AF68,
    "➜": 0x7AA2F7,
    "═": 0xF7768E,
    "◼": 0xA0A0A0,
}




def _parse_status(output):
    branch = oid = ""
    ahead = behind = stashed = untracked = False
    states = set()
    entries = iter(output.split(b"\0"))
    for entry in entries:
        if entry.startswith(b"# branch.head "):
            branch = entry[14:].decode("utf-8", "replace")
        elif entry.startswith(b"# branch.oid "):
            oid = entry[13:].decode("ascii", "replace")
        elif entry.startswith(b"# branch.ab "):
            ahead, behind = (abs(int(n)) for n in entry[12:].split())
        elif entry.startswith(b"# stash "):
            stashed = int(entry[8:]) > 0
        elif entry.startswith(b"? "):
            untracked = True
        elif entry.startswith((b"1 ", b"2 ", b"u ")):
            states.add(entry[2:4].decode("ascii").replace(".", " "))
            if entry.startswith(b"2 "):
                # Renames have a second NUL-delimited record for the old path.
                next(entries, None)

    if not branch:
        return ""
    if branch == "(detached)":
        branch = oid[:8]
    branch = "".join(c for c in branch if c.isprintable())
    parts = [branch]
    for symbol, present in (("⬆", ahead), ("⬇", behind), ("✭", stashed)):
        if present:
            parts.append(symbol)
    # Match the status symbols and XY patterns in fish_right_prompt.fish.
    for symbol, pattern in (("✚", r"[ACDMT][ MT]|[ACMT]D"),
                            ("✖", r"[ ACMRT]D"), ("✱", r"[MT]$"),
                            ("➜", r"R"), ("═", r"AA|DD|U")):
        if any(re.search(pattern, state) for state in states):
            parts.append(symbol)
    if untracked:
        parts.append("◼")
    return " ".join(parts)


def _read_status(cwd):
    try:
        result = subprocess.run(
            ["git", "--no-optional-locks", "-C", cwd, "status",
             "--porcelain=v2", "--branch", "--show-stash", "-z",
             "--untracked-files=normal"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=2,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return _parse_status(result.stdout) if result.returncode == 0 else ""


_executor = ThreadPoolExecutor(max_workers=1)
_future = None
_future_cwd = None
_current = (None, None)
_status = ""
_timer = None


def _refresh(timer_id):
    global _future, _future_cwd, _current, _status

    boss = get_boss()
    tab = boss.active_tab
    cwd = tab.get_cwd_of_active_window() if tab else None
    current = (tab.id if tab else None, cwd)
    previous = _current
    old_status = _status
    if current != _current:
        _current = current
        _status = ""

    if _future is not None and _future.done():
        if _future_cwd == cwd:
            _status = _future.result()
        _future = None
    if cwd and _future is None:
        _future_cwd = cwd
        _future = _executor.submit(_read_status, cwd)

    if previous != current or old_status != _status:
        for tab_id in {previous[0], current[0]} - {None}:
            changed_tab = boss.tab_for_id(tab_id)
            if changed_tab is not None:
                changed_tab.mark_tab_bar_dirty()


def draw_tab(draw_data, screen, tab, before, max_title_length, index, is_last, extra_data):
    global _timer

    if _timer is None:
        _timer = add_timer(_refresh, 1.0, True)
        _refresh(None)
    tab = _colored_tab(tab)
    extra_data = copy(extra_data)
    if extra_data.next_tab is not None:
        extra_data.next_tab = _colored_tab(extra_data.next_tab)
    screen.cursor.fg = as_rgb(draw_data.tab_fg(tab))
    screen.cursor.bg = as_rgb(draw_data.tab_bg(tab))
    end = draw_tab_with_powerline(
        draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
    )
    boss = get_boss()
    active_tab = boss.active_tab
    rendered_tab = boss.tab_for_id(tab.tab_id)
    if (is_last and _status and active_tab and rendered_tab
            and rendered_tab.os_window_id == active_tab.os_window_id):
        text = f" {_status} "
        width = wcswidth(text)
        if width < screen.columns - end:
            fg, bg = screen.cursor.fg, screen.cursor.bg
            screen.cursor.x = screen.columns - width
            screen.cursor.bg = as_rgb(color_as_int(draw_data.default_bg))
            branch, *symbols = _status.split(" ")
            screen.cursor.fg = as_rgb(_BRANCH_COLOR)
            screen.draw(f" {branch}")
            for symbol in symbols:
                screen.cursor.fg = as_rgb(_STATUS_COLORS[symbol])
                screen.draw(f" {symbol}")
            screen.draw(" ")
            screen.cursor.fg, screen.cursor.bg = fg, bg
    # Keep the status outside tab hitboxes so blank-space double-click still works.
    return end
