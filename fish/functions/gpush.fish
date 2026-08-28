function gpush
    set -l remote origin
    set -l ref (git rev-parse --abbrev-ref HEAD)
    if set -q argv[2]; and test "$argv[1]" = "-b"
        set ref "HEAD:$argv[2]"
        set -e argv[1..2]
    else if set -q argv[1]; and string match -qr '^https://github\.com/[^/]+/[^/]+/tree/.+$' -- "$argv[1]"
        set -l tree_url (string split -m 1 /tree/ -- "$argv[1]")
        set remote $tree_url[1]
        set ref "HEAD:$tree_url[2]"
        set -e argv[1]
    end

    set -l args
    for arg in $argv
        if test "$arg" = "-f"; or test "$arg" = "--force"
            set -a args "--force-with-lease"
        else
            set -a args $arg
        end
    end

    git push $remote $ref $args
end
