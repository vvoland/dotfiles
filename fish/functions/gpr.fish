function gpr --argument-names pr_input
    set -l number
    set -l repo_url
    
    if string match -q "https://github.com/*" $pr_input
        set repo_url (string replace -r "/pull/.*" "" $pr_input)
        set number (string match -r "/pull/(\d+)" $pr_input | tail -n 1)
        
        # Extract owner/repo from URL
        set -l owner_repo (string replace "https://github.com/" "" $repo_url)
        
        # Add upstream remote if it doesn't exist
        if not git remote get-url upstream >/dev/null 2>&1
            git remote add upstream "https://github.com/$owner_repo.git"
        end
    else
        set number $pr_input
    end
    
    git fetch upstream "refs/pull/$number/head"
    git reset --hard FETCH_HEAD
end
