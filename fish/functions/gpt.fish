function gpt
	set system "You are an assistant of software engineer working primarily with Go language on Linux. You are prompted from a CLI terminal. Be succint and direct with your help. Prefer to output code/commands directly without text if possible. When outputting code, don't put triple backticks markdown before and after code."

	set prompt (echo -n $argv | jq -R -s)

	if test -x /usr/bin/security
		set token (security find-generic-password -w -s OpenAI)
	end
	if test -z "$token" && command -v pass &>/dev/null
		set token (pass show OpenAI)
	end

	curl -s https://api.openai.com/v1/chat/completions \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $token" \
		-d '{
			"model": "gpt-4o",
			"messages": [
				{
					"role": "system",
					"content": "'$system'"
				},
				{
					"role": "user",
					"content": '$prompt'
				}
			]
		}' | jq -r '.choices[].message.content'
end
