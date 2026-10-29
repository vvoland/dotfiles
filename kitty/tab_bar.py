#!/usr/bin/env python3
"""Powerline tabs with background Git status for the focused pane."""

import os
import re
import subprocess
from concurrent.futures import ThreadPoolExecutor
from copy import copy
from random import shuffle

from kitty.fast_data_types import add_timer, get_boss, wcswidth
from kitty.tab_bar import as_rgb, draw_tab_with_powerline
from kitty.utils import color_as_int


_TAB_BACKGROUNDS = (
    0x38605B,
    0xBF360C,
    0x8A6800,
    0x2E7D32,
    0x1565C0,
    0x1565C0,
    0x3D7556,
    0x345586,
    0x465E64,
    0x6B5935,
    0x7C4B3D,
    0x75465B,
    0x495B3D,
    0x305F70,
)
_ACTIVE_FOREGROUND = 0xFFFFFF
_INACTIVE_BACKGROUND = 0x303030
_INACTIVE_FOREGROUND = 0xFFFFFF
_tab_backgrounds = []


def _colored_tab(tab, index):
    if not tab.is_active:
        return tab._replace(
            inactive_bg=_INACTIVE_BACKGROUND, inactive_fg=_INACTIVE_FOREGROUND
        )

    # Assign by position so closing or moving tabs cannot create equal neighbors.
    while len(_tab_backgrounds) < index:
        colors = list(_TAB_BACKGROUNDS)
        shuffle(colors)
        if _tab_backgrounds and colors[0] == _tab_backgrounds[-1]:
            colors[0], colors[1] = colors[1], colors[0]
        _tab_backgrounds.extend(colors)
    return tab._replace(
        active_bg=_tab_backgrounds[index - 1], active_fg=_ACTIVE_FOREGROUND
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
# Match the status symbols and XY patterns in fish_right_prompt.fish.
_STATUS_PATTERNS = (
    ("✚", r"[ACDMT][ MT]|[ACMT]D"),
    ("✖", r"[ ACMRT]D"),
    ("✱", r"[MT]$"),
    ("➜", r"R"),
    ("═", r"AA|DD|U"),
)




def _parse_status(output):
    branch = oid = ""
    ahead = behind = 0
    stashed = untracked = False
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
            # Porcelain v2 uses dots where the prompt's XY patterns expect spaces.
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
    for symbol, pattern in _STATUS_PATTERNS:
        if any(re.search(pattern, state) for state in states):
            parts.append(symbol)
    if untracked:
        parts.append("◼")
    return " ".join(parts)


def _read_status(cwd):
    """Return the status text, "" outside a repo, or None if Git did not finish."""
    try:
        result = subprocess.run(
            [
                "git", "--no-optional-locks", "-C", cwd, "status",
                "--porcelain=v2", "--branch", "--show-stash", "-z",
                "--untracked-files=normal",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=2,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    return _parse_status(result.stdout) if result.returncode == 0 else ""


# Keep Git subprocess waits off Kitty's UI thread.
_executor = ThreadPoolExecutor(max_workers=1)
_status_future = None
_status_cwd = None
_active_context = (None, None)
_fish_cwds = {}
_status = ""
_timer = None


def _fish_cwd(window):
    """Return the cwd of the window's fish shell, remembered while it runs a job."""
    # Prompt commands such as git share the shell's process group, so match
    # fish by name; login shells have a leading "-" in argv[0].
    for process in sorted(window.child.foreground_processes, key=lambda p: p["pid"]):
        cmdline = process["cmdline"]
        if cmdline and os.path.basename(cmdline[0]).lstrip("-") == "fish":
            if process["cwd"]:
                _fish_cwds[window.id] = process["cwd"]
            break
    return _fish_cwds.get(window.id)


def _refresh(timer_id):
    global _status_future, _status_cwd, _active_context, _status

    boss = get_boss()
    tab = boss.active_tab
    window = tab.active_window if tab else None
    cwd = _fish_cwd(window) if window else None
    current = (tab.id if tab else None, cwd)
    previous = _active_context
    old_status = _status
    if current[0] != _active_context[0]:
        _status = ""
    _active_context = current

    if _status_future is not None and _status_future.done():
        # Focus may have moved to a different directory while Git was running.
        status = _status_future.result()
        if _status_cwd == cwd and status is not None:
            _status = status
        _status_future = None
    if cwd and _status_future is None:
        _status_cwd = cwd
        _status_future = _executor.submit(_read_status, cwd)

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
    tab = _colored_tab(tab, index)
    # Powerline uses the next tab's background for the separator color.
    extra_data = copy(extra_data)
    if extra_data.next_tab is not None:
        extra_data.next_tab = _colored_tab(extra_data.next_tab, index + 1)
    screen.cursor.fg = as_rgb(draw_data.tab_fg(tab))
    screen.cursor.bg = as_rgb(draw_data.tab_bg(tab))
    end = draw_tab_with_powerline(
        draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
    )
    boss = get_boss()
    active_tab = boss.active_tab
    rendered_tab = boss.tab_for_id(tab.tab_id)
    if (
        is_last and _status and active_tab and rendered_tab
        and rendered_tab.os_window_id == active_tab.os_window_id
    ):
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
