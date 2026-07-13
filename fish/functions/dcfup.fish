function dcfup --wraps='docker compose up --remove-orphans --build --force-recreate' --description 'alias dcfup=docker compose up --remove-orphans --build --force-recreate'
    docker compose up --remove-orphans --build --force-recreate $argv
end
