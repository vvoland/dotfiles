function nvim-conflicts
    git status --porcelain | grep "^UU\|^AA\|^DD" | cut -d' ' -f2 | xargs nvim -c 'let @/="^=======$"' -c 'set hlsearch'
end
