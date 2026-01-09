function gpush
    set -l args
    for arg in $argv
        if test "$arg" = "-f"; or test "$arg" = "--force"
            set -a args "--force-with-lease"
        else
            set -a args $arg
        end
    end
    git push origin (git rev-parse --abbrev-ref HEAD) $args
end
