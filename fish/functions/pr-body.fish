function pr-body --argument master remote
    if test -z "$remote"
        set remote upstream
    end
    set merge_base "$master...HEAD"

    git log --no-show-signature --reverse --format='### %s%n%n%w(1000,2,2)%b%n' "$remote/$merge_base" -- | grep -v Signed-off
end
