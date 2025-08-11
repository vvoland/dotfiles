function ociref
    set -l reference $argv[1]
    set -l repo (string split --max 1 '@' -- $reference)[1]
    set -l digest ''
    set -l tag 'latest'

    if string match -q '*@*' -- $reference
        set digest (string split --max 1 '@' -- $reference)[2]
    else if string match -q '*:*' -- $repo
        set -l parts (string split --max 1 ':' -- $repo)
        set repo $parts[1]
        set tag $parts[2]
    end

    echo "$repo"
    echo  "$tag"
    echo "$digest"
end
