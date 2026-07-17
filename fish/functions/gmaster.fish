function gmaster
	set remote "upstream"
	if git remote -v 2>/dev/null | ! grep upstream
		set remote "origin"
	end
	git reset --hard $remote/master $argv
end
