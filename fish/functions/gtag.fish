function gtag --argument tag --argument ref
    git tag -a -s "$tag" -m "$tag" $ref
end
