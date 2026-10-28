"""Powerline tabs with background Git status for the focused pane."""

import re
import subprocess
from concurrent.futures import ThreadPoolExecutor
from copy import copy
from random import Random

from kitty.fast_data_types import add_timer, get_boss, wcswidth
from kitty.tab_bar import as_rgb, draw_tab_with_powerline
from kitty.utils import color_as_int


# Match the random background palette in fish_prompt.fish.
_TAB_BACKGROUNDS = tuple(int(color, 16) for color in """
fce4ec f8bbd0 f48fb1 f06292 ec407a e91e63 d81b60 c2185b ad1457 880e4f ff80ab ff4081 f50057 c51162
f3e5f5 e1bee7 ce93d8 ba68c8 ab47bc 9c27b0 8e24aa 7b1fa2 6a1b9a 4a148c ea80fc e040fb d500f9 aa00ff
ede7f6 d1c4e9 b39ddb 9575cd 7e57c2 673ab7 5e35b1 512da8 4527a0 311b92 b388ff 7c4dff 651fff 6200ea
e8eaf6 c5cae9 9fa8da 7986cb 5c6bc0 3f51b5 3949ab 303f9f 283593 1a237e 8c9eff 536dfe 3d5afe 304ffe
e3f2fd bbdefb 90caf9 64b5f6 42a5f5 2196f3 1e88e5 1976d2 1565c0 0d47a1 82b1ff 448aff 2979ff 2962ff
e1f5fe b3e5fc 81d4fa 4fc3f7 29b6f6 03a9f4 039be5 0288d1 0277bd 01579b 80d8ff 40c4ff 00b0ff 0091ea
e0f7fa b2ebf2 80deea 4dd0e1 26c6da 00bcd4 00acc1 0097a7 00838f 006064 84ffff 18ffff 00e5ff 00b8d4
e0f2f1 b2dfdb 80cbc4 4db6ac 26a69a 009688 00897b 00796b 00695c 004d40 a7ffeb 64ffda 1de9b6 00bfa5
f9fbe7 f0f4c3 e6ee9c dce775 d4e157 cddc39 c0ca33 afb42b 9e9d24 827717 f4ff81 eeff41 c6ff00 aeea00
fffde7 fff9c4 fff59d fff176 ffee58 ffeb3b fdd835 fbc02d f9a825 f57f17 ffff8d ffff00 ffea00 ffd600
fff8e1 ffecb3 ffe082 ffd54f ffca28 ffc107 ffb300 ffa000 ff8f00 ff6f00 ffe57f ffd740 ffc400 ffab00
fff3e0 ffe0b2 ffcc80 ffb74d ffa726 ff9800 fb8c00 f57c00 ef6c00 e65100 ffd180 ffab40 ff9100 ff6d00
fbe9e7 ffccbc ffab91 ff8a65 ff7043 ff5722 f4511e e64a19 d84315 bf360c ff9e80 ff6e40 ff3d00 dd2c00
efebe9 d7ccc8 bcaaa4 a1887f 8d6e63 795548 6d4c41 5d4037 4e342e 3e2723
fafafa f5f5f5 eeeeee e0e0e0 bdbdbd 9e9e9e 757575 616161 424242 212121
eceff1 cfd8dc b0bec5 90a4ae 78909c 607d8b 546e7a 455a64 37474f 263238
""".split())


def _colored_tab(tab):
    # Seed by identity so titles, tab order, and redraws do not change the color.
    background = Random(tab.tab_id).choice(_TAB_BACKGROUNDS)
    if not tab.is_active:
        background = sum(
            int(((background >> shift) & 0xFF) * 0.6) << shift
            for shift in (16, 8, 0)
        )
    brightness = sum(
        ((background >> shift) & 0xFF) * weight
        for shift, weight in ((16, 299), (8, 587), (0, 114))
    ) / 1000
    foreground = 0x000000 if brightness > 130 else 0xFFFFFF
    if tab.is_active:
        return tab._replace(active_bg=background, active_fg=foreground)
    return tab._replace(
        inactive_bg=background,
        inactive_fg=foreground,
    )




_BRANCH_COLOR = 0x73DACA
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
