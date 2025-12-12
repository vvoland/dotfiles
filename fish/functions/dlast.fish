function dlast
    docker exec -it (docker ps --latest -q) bash
end
