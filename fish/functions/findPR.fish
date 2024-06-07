function findPR --arg ref
	set upstreamUrl (git config --get remote.upstream.url)
	set url "$upstreamUrl/pulls?q=type%3Apr+$ref"
	if test -f /usr/bin/open
		open "$url"
	else
		echo "$url"
	end
end
