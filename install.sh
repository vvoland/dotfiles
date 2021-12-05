#!/bin/sh

if [ ! -f "scripts/bin/config.sh" ]; then
    echo "No scripts/bin/config.sh!"
    echo "Please copy config.sh.template file in scripts/bin"
    echo "And save it as config.sh"
    exit 1
fi

XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}

git submodule init
git submodule update --remote --recursive

stow scripts
stow shell

stow i3
stow polybar
stow dunst
stow rofi
stow compton

# Neovim with dein
mkdir -p "${XDG_CACHE_HOME}/dein/"
git clone https://github.com/Shougo/dein.vim "${XDG_CACHE_HOME}/dein/repos/github.com/Shougo/dein.vim"
stow neovim

# Zsh & oh-my-zsh & bullet-train theme
git clone https://github.com/robbyrussell/oh-my-zsh "${XDG_CACHE_HOME}/oh-my-zsh/"
install zsh/bullet-train.zsh-theme "${XDG_CACHE_HOME}/oh-my-zsh/themes/"
stow zsh --ignore="*.zsh-theme"

git clone https://github.com/zsh-users/zsh-autosuggestions ${XDG_CACHE_HOME}/oh-my-zsh/plugins/zsh-autosuggestions
