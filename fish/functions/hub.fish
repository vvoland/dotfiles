function hub --argument action --argument ref
    set -l r (ociref "$ref")
    set repo $r[1]
    set tag  $r[2]
    set digest $r[3]
    set tag_or_digest "$tag"
    if test -z "$tag"
        set tag_or_digest "$digest"
    end

    set -l token (curl -fsSL "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$repo:pull" | jq --raw-output '.token')

    switch $action
        case blob
            test -z "$repo" && echo "repo is empty" && exit 1
            test -z "$digest" && echo "digest is empty" && exit 1
            set -l u "https://registry-1.docker.io/v2/$repo/blobs/$digest"
            curl -s -f -H "Authorization: Bearer $token" -L "$u"
        case manifest
            test -z "$repo" && echo "repo is empty" && exit 1
            test -z "$tag_or_digest" && echo "tag and digest is empty" && exit 1
            set -l u "https://registry-1.docker.io/v2/$repo/manifests/$tag_or_digest"
            curl -s -f -H 'Accept: *' -H "Authorization: Bearer $token" -L "$u"
    end
end
