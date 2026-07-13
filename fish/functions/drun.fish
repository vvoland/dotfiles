function drun
  docker run --rm -v (pwd):(pwd) -w (pwd) $argv
end
