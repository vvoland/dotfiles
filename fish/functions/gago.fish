function gago --wraps='git add "*.go"' --description 'alias gago=git add "*.go"'
    git add "*.go" $argv
end
