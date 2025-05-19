function gomodupdates
    go list -m -u -mod=readonly \
        -f '{{if and (not .Indirect) .Update}}{{.Path}} {{.Version}} → {{.Update.Version}}{{end}}' \
        all
end
