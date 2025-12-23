function cagent
	set token ""
	if test -x /usr/bin/security
		set token (security find-generic-password -w -s OpenAI)
	end
	if test -z "$token" && command -v pass &>/dev/null
		set token (pass show OpenAI)
	end
	set openai "$token"

	set token ""
	if test -x /usr/bin/security
		set token (security find-generic-password -w -s Anthropic)
	end
	if test -z "$token" && command -v pass &>/dev/null
		set token (pass show Anthropic)
	end
	set claude "$token"

	#CAGENT_MODELS_GATEWAY=https://gw.docker.com/models
	set bin /usr/bin/cagent
	set bin $HOME/src/cagent/dist/cagent
	TELEMETRY_ENABLED=false OPENAI_API_KEY=$openai ANTHROPIC_API_KEY=$claude $bin $argv
	# set pwd (pwd)
	# docker run --rm -it \
	# 	-v "$pwd:$pwd" \
	# 	-w "$pwd" \
	# 	-u 1000:1000 \
	# 	-e "OPENAI_API_KEY=$openai" \
	# 	-e "ANTHROPIC_API_KEY=$claude" \
	# 	cagent $argv
end
