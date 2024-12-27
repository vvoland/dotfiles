function metin --argument suffix
    trap "docker rm -f metin$suffix -t 1" INT
    docker run -d --rm --name metin$suffix (dckrapp --gpu) -v metin:/game metin
    docker logs -f metin$suffix
end
