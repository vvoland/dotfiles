function tower --argument action
    if test -z "$action"
        set action wake
    end

    # might be useful to do:
    # echo "$(whoami) ALL=(ALL) NOPASSWD: /usr/sbin/ether-wake" >>/etc/sudoers.d/10-etherwake
    set host archtower.lan
    set mac  00:D8:61:BC:57:14

    sudo ether-wake "$mac"

    if not ping -W 1 -c 1 $host >/dev/null 2>&1
        set -l frames '.' 'o' 'O'
        set -l i 1

        # Hide cursor
        printf '\e[?25l' 1>&2

        while not ping -W 0.5 -c 1 $host >/dev/null 2>&1
            # Print colored spinner + message
            printf '\r\033[36m%s\033[0m \033[33mWaiting for wake up…\033[0m \033[90m(%s)\033[0m ' $frames[$i] $host 1>&2

            set i (math "$i + 1")
            if test $i -gt (count $frames)
                set i 1
            end
            sleep 0.25
        end

        # Clear line and show cursor again
        printf '\r\033[2K' 1>&2
        printf '\e[?25h' 1>&2
    end

    switch $action
        case ssh
            ssh -A -t "woland@$host" systemd-inhibit fish
        case wake
            echo "$host is awake"
        case sway
            waypipe ssh -A "woland@$host" sway
        case '*'
            echo "Invalid action: $action"
            return 2
    end
#     ssh -tt "woland@$host" sh -x -c 'sleep 5
# sudo systemd-inhibit \
#         --who="SSH session" \
#         --why="Remote shell active" \
#         --mode=block \
#         --what=sleep:handle-lid-switch \
#         sh -x -c "while [ $(who | grep -c pts/) -gt 0 ]; do sleep 1; done; exit"
#     '
end
