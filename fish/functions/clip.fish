function clip --argument action
    switch $action
        case copy
            if command -v pbcopy 2>&1 >/dev/null
                pbcopy
                return
            end
            if command -v wl-copy 2>&1 >/dev/null
                wl-copy
                return
            end
            if command -v xclip 2>&1 >/dev/null
                xclip -sel clip
                return
            end
        case paste
            if command -v pbpaste 2>&1 >/dev/null
                pbpaste $argv
                return
            end
            if command -v wl-paste 2>&1 /dev/null
                wl-paste $argv
                return
            end
            if command -v wl-paste 2>&1 /dev/null
                xclip $argv
                return
            end
    end
    return 1
end
