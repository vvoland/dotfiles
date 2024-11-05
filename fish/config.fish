set fish_greeting

set theme Dark

if test -f /usr/bin/defaults
    set theme (defaults read -g AppleInterfaceStyle 2>/dev/null)
end

export EDITOR=nvim
export TERM=xterm
if test "$theme" = "Dark"
    /usr/local/bin/theme.sh hemisu-dark
else
    /usr/local/bin/theme.sh google-light
end

