function cpaste
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
    return 1
end
