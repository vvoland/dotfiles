function commit --wraps='git commit -v' --description 'alias commit=git commit -v'
  git commit -v $argv
        
end
