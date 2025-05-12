#!/usr/bin/python3
import socket

hostname=socket.gethostname()

windrider="""
font_size 14
"""

def main():
    if hostname == "windrider":
        print(windrider)

if __name__ == "__main__":
    main()
