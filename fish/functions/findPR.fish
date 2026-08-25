function findPR --arg ref
	set upstreamUrl (git config --get remote.upstream.url)
	set upstreamUrl (string replace -r '^git@github\.com:' 'https://github.com/' "$upstreamUrl")
	set upstreamUrl (string replace -r '\.git$' '' "$upstreamUrl")
	set url "$upstreamUrl/pulls?q=type%3Apr+$ref"
	if test -f /usr/bin/open
		open "$url"
	else
		echo "$url"
	end
end
