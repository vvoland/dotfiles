function gpush
    set -l ref (git rev-parse --abbrev-ref HEAD)
    if set -q argv[2]; and test "$argv[1]" = "-b"
        set ref "HEAD:$argv[2]"
        set -e argv[1..2]
    end

    set -l args
    for arg in $argv
        if test "$arg" = "-f"; or test "$arg" = "--force"
            set -a args "--force-with-lease"
        else
            set -a args $arg
        end
    end

    git push origin $ref $args
end
