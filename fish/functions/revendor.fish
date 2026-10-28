function revendor
    set gitdir (git rev-parse --git-common-dir)
    set project (basename (string replace -r '/\.git$' '' -- $gitdir))

    if test -f docker.Makefile
        make -f docker.Makefile vendor
    else if test -f pinata.sh
        set img (grep -Eo "golang:[0-9.]+" pinata.sh)
        docker run --rm -it -v ./:/proj -w /proj $img sh -c 'go mod tidy && go mod vendor'
    else if test "$project" = moby; or test "$project" = docker
        echo "./hack/vendor.sh" | make BIND_DIR=. shell
    else
        #set ver (go list -m -json | jq -r .GoVersion)
        docker run --rm --pull=always -v ./:/proj -w /proj "golang:latest" sh -c 'go mod tidy && go mod vendor'
    end
end
