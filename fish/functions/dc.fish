function dc --wraps='docker -c creep ' --description 'alias dc=docker -c creep '
  docker -c creep  $argv
        
end
