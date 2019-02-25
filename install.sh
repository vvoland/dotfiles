#!/bin/sh

stow polybar
stow dunst

mkdir -p "~/.cache/dein/"
git clone https://github.com/Shougo/dein.vim "~/.cache/dein/repos/github.com/Shougo/dein.vim"
stow neovim
