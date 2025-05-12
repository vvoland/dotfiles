set fish_greeting

set theme Dark

if test -f /usr/bin/defaults
    set theme (defaults read -g AppleInterfaceStyle 2>/dev/null)
end

set set_theme theme.sh

function set_theme --arg theme
    if command -v "theme.sh" >dev/null
        theme.sh "$theme"
        return
    end
    /usr/local/bin/theme.sh
end

export EDITOR=nvim
export TERM=xterm
if test "$theme" = "Dark"
    $set_theme hemisu-dark
else
    $set_theme google-light
end
