function gh-pr-single --argument branch
    if test (count $argv) -lt 2
        echo "Usage: gh-pr-single <branch> <hash1> [hash2] ..." >&2
        return 1
    end
    set -l hashes $argv[2..-1]

    git fetch upstream
    or return 1

    set -l base
    for b in main master
        if git rev-parse --verify -q "upstream/$b" >/dev/null
            set base $b
            break
        end
    end
    if test -z "$base"
        echo "No upstream/main or upstream/master found" >&2
        return 1
    end

    # Resolve before switching to the worktree so relative refs like HEAD~1 refer to the current checkout.
    set -l commits
    for h in $hashes
        set -l c (git rev-parse --verify -q "$h^{commit}")
        or begin
            echo "Unknown commit: $h" >&2
            return 1
        end
        set -a commits $c
    end

    # Use a separate worktree so the current checkout is left untouched.
    set -l old (git rev-parse --verify -q "refs/heads/$branch")
    set -l dir (mktemp -d)
    git worktree add --no-track -B "$branch" "$dir" "upstream/$base"
    or begin
        rmdir "$dir"
        return 1
    end

    if not git -C "$dir" cherry-pick $commits
        git -C "$dir" cherry-pick --abort
        git worktree remove --force "$dir"
        if test -n "$old"
            git branch -f "$branch" "$old"
            echo "Cherry-pick failed; restored branch $branch" >&2
        else
            git branch -D "$branch"
            echo "Cherry-pick failed; removed branch $branch" >&2
        end
        return 1
    end

    set -l force --force
    set -l origin_repo (gh-repo origin)
    set -l upstream_repo (gh-repo upstream)
    if test -z "$origin_repo"; or test "$origin_repo" = "$upstream_repo"
        echo "origin is not a fork of upstream; not force pushing" >&2
        set force
    end

    if not git push $force -u origin "$branch"
        git worktree remove "$dir"
        return 1
    end

    pushd "$dir"
    master=$base gh-pr
    set -l ret $status
    popd

    git worktree remove "$dir"
    return $ret
end
