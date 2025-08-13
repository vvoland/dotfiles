function gh-pr --argument-names nofill
    set branch (git rev-parse --abbrev-ref HEAD)

    set repo (gh-repo upstream)

    echo "Repo: $repo"
    echo "Branch: $branch"

    if test -n "$nofill"
        gh pr create -w --head "vvoland:$branch" -R "$repo" -a "@me" "$argv"
        exit
    end

    set body (git log --reverse --format="### %s%n%n%b" (git merge-base HEAD upstream)...HEAD | grep -v Signed-off)
    set title (git log --reverse --format="%s" (git merge-base HEAD upstream)...HEAD | head -n1)

    gh pr create -w --head "vvoland:$branch" -R "$repo" --title "$title" -a "@me" --body "$body" -B "$BASE" "$argv"
end
