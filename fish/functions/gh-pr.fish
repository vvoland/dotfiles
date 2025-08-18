function gh-pr --argument-names nofill
    set branch (git rev-parse --abbrev-ref HEAD)

    set repo (gh-repo upstream)

    echo "Repo: $repo"
    echo "Branch: $branch"

    if test -n "$nofill"
        gh pr create -w --head "vvoland:$branch" -R "$repo" -a "@me" "$argv"
        exit
    end

    set master (git merge-base HEAD upstream/master)
    if test -z "$master"
        set master (git merge-base HEAD upstream/main)
    end
    set merge_base "$master...HEAD"

    set body (git log --reverse --format="### %s%n%n%b" "$merge_base" | grep -v Signed-off)
    set title (git log --reverse --format="%s" "$merge_base" | head -n1)

    echo "$body" | gh pr create -w --head "vvoland:$branch" -R "$repo" --title "$title" -a "@me" --body @ $argv
end
