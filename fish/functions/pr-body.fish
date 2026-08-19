function pr-body --argument master
    set merge_base "$master...HEAD"

    git log --no-show-signature --reverse --format='### %s%n%n%w(1000,2,2)%b%n' "upstream/$merge_base" -- | grep -v Signed-off
end
