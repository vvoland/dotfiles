function ffixup
set files (git diff --name-only --cached | head -n1 | xargs)
set commit (git log --pretty=oneline $files | fzf --tiebreak=index | awk "{printf \$1}")
git commit --fixup $commit
end
