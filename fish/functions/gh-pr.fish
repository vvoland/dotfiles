function gh-pr --argument-names nofill
    set branch (git rev-parse --abbrev-ref HEAD)

    set repo (gh-repo upstream)

    echo "Repo: $repo"
    echo "Branch: $branch"

    if test -n "$nofill"
        gh pr create -w --head "vvoland:$branch" -R "$repo" -a "@me" "$argv"
        exit
    end

    set master (git merge-base HEAD upstream/master 2>/dev/null)
    if test -z "$master"
        set master (git merge-base HEAD upstream/main 2>/dev/null)
    end
    set merge_base "$master...HEAD"

    set body (git log --reverse --format='### %s%n%n%b%n' "$merge_base" | grep -v Signed-off | string collect)
    set title (git log --reverse --format="%s" "$merge_base" | head -n1)

    gh pr create -w --head "vvoland:$branch" -R "$repo" --title "$title" -a "@me" --body "$body" $argv
end
