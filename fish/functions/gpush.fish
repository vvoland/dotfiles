function gpush
    git push origin (git rev-parse --abbrev-ref HEAD) $argv
end
