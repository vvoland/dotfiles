function garc
  git commit --amend -sS -v --no-edit && git rebase --continue $argv
end
