function gfp --wraps='commit --fixup (gpick)' --description 'alias gfp=commit --fixup (gpick)'
  commit --fixup (gpick) $argv
        
end
