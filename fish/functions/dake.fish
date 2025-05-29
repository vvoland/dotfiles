function dake --argument target --argument out
    if test -n "$out"
        docker build --target "$target" -o "$out" .
    else
        docker build --target "$target" -o type=cacheonly .
    end
end
