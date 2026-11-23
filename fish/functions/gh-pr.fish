function gh-pr
    set branch (git rev-parse --abbrev-ref HEAD)

    set -l remote upstream
    set -l head "vvoland:$branch"
    set -l exclude
    if not git remote get-url "$remote" >/dev/null 2>&1
        set remote origin
        set head "$branch"
        # A pushed topic branch is not its own base.
        set exclude --decorate-refs-exclude="refs/remotes/$remote/$branch"
    end

    set repo (gh-repo "$remote")
    or return 1

    echo "Repo: $repo"
    echo "Branch: $branch"

    if test -z "$master"
        set master (git log --format='%d' -n 50 \
            --decorate-refs="refs/remotes/$remote/*" \
            --decorate-refs-exclude="refs/remotes/$remote/HEAD" $exclude |
            string match -g -r "$remote/([\\w./-]+)" |
            head -n1
        )
    end

    if test -z "$master"
        echo "No base branch found" >&2
        return 1
    end

    echo "Base branch: $master"

    if test -n "$nofill"
        gh pr create -w --head "$head" -R "$repo" -a "@me" "$argv"
        return
    end

    set merge_base "$master...HEAD"

    set body (pr-body "$master" "$remote" | string collect)
    set title (git log --no-show-signature --reverse --format="%s" "$remote/$merge_base" -- | head -n1)

    gh pr create -B "$master" -w --head "$head" -R "$repo" --title "$title" -a "@me" --body "$body" $argv
end
