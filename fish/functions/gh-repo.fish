function gh-repo --argument remote
    if test -z "$remote"
        set remote origin
    end
    set -l url (git remote get-url "$remote")
    or return 1

    gh repo view "$url" --json nameWithOwner --jq .nameWithOwner
end
