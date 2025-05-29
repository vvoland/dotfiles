#!/usr/bin/python3
import socket

hostname=socket.gethostname()

windrider="""
font_size 17.3
font_family      family="Terminus (TTF)"
bold_font        auto
italic_font      auto
bold_italic_font auto
"""

macbook="""
shell /opt/homebrew/bin/fish
font_size 14
font_family      family="Terminus (TTF)"
bold_font        auto
italic_font      auto
bold_italic_font auto
"""

def main():
    match hostname.lower():
        case "windrider":
            print(windrider)
        case "macbookpro.lan":
            print(macbook)

if __name__ == "__main__":
    main()
