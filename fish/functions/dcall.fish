function dcall
    set tmp (mktemp)
    docker build --iidfile "$tmp" .
    set img (cat "$tmp")
    rm "$tmp"
    docker run --rm -it "$img" $argv
end
