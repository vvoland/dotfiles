#!/usr/bin/python3
import socket

hostname = socket.gethostname()

windrider = """
font_size 14
font_family      family="Adwaita Mono"

bold_font        auto
italic_font      auto
bold_italic_font auto
"""

macbook = """
shell /opt/homebrew/bin/fish
font_size 14
font_family      family="Terminus (TTF)"
bold_font        auto
italic_font      auto
bold_italic_font auto

background_opacity 0.9
background_blur 64
"""


def main():
    h = hostname.lower()
    cfg = {
        "windrider": windrider,
        "fqpf6ww46h": macbook,
        "macbookpro.lan": macbook,
    }
    print(cfg[h])


if __name__ == "__main__":
    main()
