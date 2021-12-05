#!/bin/bash
set -e

for i in {1..10}; do
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Alt>$i']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Shift><Alt>$i']"
done

# VimPlug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# vimrc
ln -s $(pwd)/vimrc ~/.vimrc

mkdir -p ~/.local/bin

# theme.sh
curl -o ~/.local/bin/theme.sh 'https://raw.githubusercontent.com/lemnos/theme.sh/master/theme.sh' && chmod +x ~/.local/bin/theme.sh

# fish
mkdir ~/.config/fish
ln -sf $(pwd)/config.fish ~/.config/fish/config.fish

# tmux
ln -s $(pwd)tmux.conf ~/.tmux.conf
