#!/bin/bash

# 0-9 workspaces
for i in {1..10}; do
    key="$i"
    # Bind 10 workspace to 0 key
    if [ $i -eq 10 ]; then
        key=0
    fi
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Alt>$key']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Shift><Alt>$key']"
done

# Disable capslock
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:none']"

