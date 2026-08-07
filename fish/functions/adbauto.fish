function adbauto
    set -l service "_adb-tls-connect._tcp"
    set -l filter ""

    if test (count $argv) -ge 1
        set filter $argv[1]
    end

    if not command -q avahi-browse
        echo "error: avahi-browse not found" >&2
        exit 1
    end

    if not command -q adb
        echo "error: adb not found" >&2
        exit 1
    end

    echo "Searching for ADB devices..."

    set -l names
    set -l endpoints

    for line in (timeout 5 avahi-browse -rtp $service 2>/dev/null)
        set -l fields (string split ';' -- $line)

        # Parsed avahi-browse format:
        # 1  = result marker
        # 2  = interface
        # 3  = protocol
        # 4  = service name
        # 5  = service type
        # 6  = domain
        # 7  = hostname
        # 8  = address
        # 9  = port

        if test (count $fields) -lt 9
            continue
        end

        if test "$fields[1]" != "="
            continue
        end

        # Prefer IPv4. This also avoids needing [addr]:port handling.
        if test "$fields[3]" != "IPv4"
            continue
        end

        set -l name $fields[4]
        set -l ip $fields[8]
        set -l port $fields[9]

        if test -n "$filter"
            if not string match -qi "*$filter*" -- $name
                continue
            end
        end

        set -l endpoint "$ip:$port"

        # Avoid duplicates.
        if contains -- $endpoint $endpoints
            continue
        end

        set -a names $name
        set -a endpoints $endpoint
    end

    set -l count (count $endpoints)

    if test $count -eq 0
        echo "No ADB wireless devices found." >&2
        exit 1
    end

    set -l selected 1

    if test $count -gt 1
        echo
        echo "Found $count devices:"
        echo

        for i in (seq $count)
            printf "  %d) %-30s %s\n" $i $names[$i] $endpoints[$i]
        end

        echo
        read -P "Select device [1-$count]: " selected

        if not string match -qr '^[0-9]+$' -- $selected
            echo "Invalid selection." >&2
            exit 1
        end

        if test $selected -lt 1 -o $selected -gt $count
            echo "Invalid selection." >&2
            exit 1
        end
    end

    set -l endpoint $endpoints[$selected]

    echo "Connecting to $endpoint..."
    adb connect $endpoint
end
