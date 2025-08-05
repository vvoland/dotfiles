function gup
  git fetch upstream && git reset --hard upstream/(git rev-parse --abbrev-ref HEAD) $argv
end
