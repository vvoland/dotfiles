function gpr --argument-names number
    git fetch upstream "refs/pull/$number/head"
    git reset --hard FETCH_HEAD
end
