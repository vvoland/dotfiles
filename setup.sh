#!/bin/bash
set -e

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

mkdir -p ~/.local/bin
# theme.sh
curl -Lo ~/.local/bin/theme.sh https://raw.githubusercontent.com/lemnos/theme.sh/master/bin/theme.sh && chmod +x ~/.local/bin/theme.sh

# fish
mkdir -p ~/.config/fish
ln -sf $(pwd)/fish/config.fish ~/.config/fish/config.fish
ln -sf $(pwd)/fish/functions ~/.config/fish/functions

# tmux
mkdir -p ~/.config/tmux
ln -s $(pwd)/tmux.conf ~/.config/tmux/tmux.conf


# VimPlug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# vimrc
ln -s $(pwd)/vimrc ~/.vimrc
