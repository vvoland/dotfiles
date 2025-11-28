function gftag --argument tag --argument ref
    git tag -f -a -s "$tag" -m "$tag" $ref
end
