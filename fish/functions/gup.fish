function gup
  git fetch origin &
  if git remote -v 2>/dev/null | grep -q upstream
    git fetch upstream
  end
  wait
end
