set fish_greeting

set --local theme Dark

if test -f /usr/bin/defaults
    set --local theme (defaults read -g AppleInterfaceStyle 2>/dev/null)
end

if status is-interactive
    export EDITOR=nvim
    export TERM=xterm
    if test "$theme" = "Dark"
        theme.sh hemisu-dark
    else
        theme.sh google-light
    end
end
