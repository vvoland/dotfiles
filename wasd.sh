#!/bin/sh

tar -c /usr/share/X11/xkb >xkb-bak.tar

cp {,/}usr/share/X11/xkb/compat/complete
cp {,/}usr/share/X11/xkb/symbols/pl
cp {,/}usr/share/X11/xkb/types/complete

