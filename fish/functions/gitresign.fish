function gitresign
  while git commit --amend -sS -v --no-edit; and git rebase --continue; end
end
