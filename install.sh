#!/bin/sh

XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}

git submodule init
git submodule update --remote --recursive

stow polybar
stow dunst

# Neovim with dein
mkdir -p "${XDG_CACHE_HOME}/dein/"
git clone https://github.com/Shougo/dein.vim "${XDG_CACHE_HOME}/dein/repos/github.com/Shougo/dein.vim"
stow neovim

# Zsh & oh-my-zsh & bullet-train theme
git clone https://github.com/robbyrussell/oh-my-zsh "${XDG_CACHE_HOME}/oh-my-zsh/"
install zsh/bullet-train.zsh-theme "${XDG_CACHE_HOME}/oh-my-zsh/themes/"
stow zsh --ignore="*.zsh-theme"
