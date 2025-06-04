function docker-merge
    if test (count $argv) -lt 2
        echo "Usage: $argv[0] <resulting-image-name> <image1> <image2> ... <imageN>"
        exit 1
    end
    
    set TARGET $argv[1]
    set IMAGES $argv[2..-1]
    
    begin
        echo "FROM scratch"
        for image in $IMAGES
            echo "COPY --from=$image / /"
        end
    end | docker build -t $TARGET -
end
