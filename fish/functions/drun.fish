function drun --wraps='docker run --cap-drop ALL --security-opt no-new-privileges -u 1000:1000 -v (pwd):(pwd) -w (pwd)' --wraps='docker run --rm --cap-drop ALL --security-opt no-new-privileges -u 1000:1000 -v (pwd):(pwd) -w (pwd)' --description 'alias drun=docker run --rm --cap-drop ALL --security-opt no-new-privileges -u 1000:1000 -v (pwd):(pwd) -w (pwd)'
  docker run --rm --cap-drop ALL --security-opt no-new-privileges -u 1000:1000 -v (pwd):(pwd) -w (pwd) $argv
        
end
