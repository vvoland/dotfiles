function gup
  git reset --hard upstream/(git rev-parse --abbrev-ref HEAD) $argv
end
