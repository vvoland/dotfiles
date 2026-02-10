function gwt --description 'Git worktree wrapper: create, enter, list, or remove worktrees'
    argparse --name=gwt 'h/help' 'l/list' 'r/rm' -- $argv
    or return 1

    # --- Help ---
    if set -q _flag_help
        echo "Usage:"
        echo "  gwt <name>          Create (if needed) and cd into a worktree"
        echo "  gwt -l, --list      List all worktrees"
        echo "  gwt --rm <name>     Remove a worktree"
        echo "  gwt -h, --help      Show this help"
        return 0
    end

    # --- List ---
    if set -q _flag_list
        git worktree list
        return $status
    end

    # --- Remove ---
    if set -q _flag_rm
        if test (count $argv) -eq 0
            echo "gwt: --rm requires a worktree name" >&2
            return 1
        end

        set -l name $argv[1]
        set -l root (git rev-parse --git-common-dir 2>/dev/null)
        or begin
            echo "gwt: not inside a git repository" >&2
            return 1
        end

        # Resolve to absolute path of the common git dir's parent
        set root (builtin realpath "$root/..")

        set -l wt_path "$root/$name"

        if not test -d "$wt_path"
            echo "gwt: worktree directory '$wt_path' does not exist" >&2
            return 1
        end

        git worktree remove "$wt_path"
        return $status
    end

    # --- Create / Enter ---
    if test (count $argv) -eq 0
        echo "gwt: please provide a worktree name (or use --list, --rm)" >&2
        return 1
    end

    set -l name $argv[1]
    set -l root (git rev-parse --git-common-dir 2>/dev/null)
    or begin
        echo "gwt: not inside a git repository" >&2
        return 1
    end

    # Resolve to absolute path of the common git dir's parent
    set root (builtin realpath "$root/..")

    set -l wt_path "$root/$name"

    # If the worktree directory already exists, just cd into it
    if test -d "$wt_path"
        echo "gwt: worktree '$name' already exists, entering..."
        cd "$wt_path"
        return $status
    end

    # Otherwise create a new worktree and cd into it
    # Use -b to create a new branch with the same name as the worktree
    echo "gwt: creating worktree '$name'..."
    git worktree add -b "$name" "$wt_path"
    or begin
        # If branch already exists, try without -b (use existing branch)
        echo "gwt: branch '$name' may already exist, trying without -b..."
        git worktree add "$wt_path" "$name"
        or return 1
    end

    cd "$wt_path"
    return $status
end
