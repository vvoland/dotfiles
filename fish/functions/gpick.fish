function gpick --arg file
	git log --pretty=oneline $file | fzf --tiebreak=index | awk "{printf \$1}"
end
