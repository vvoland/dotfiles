function gh-repo --argument remote
    if test -z "$remote"
	set -l remote "origin"
    end
    set -l repo (git remote -v | grep "$remote" | grep 'github.com' | cut -d ':' -f2 | cut -d ' ' -f1 | head -n1)
    echo (string replace '.git' '' $repo)
end
