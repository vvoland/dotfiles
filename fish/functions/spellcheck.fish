function spellcheck
	set system (echo "I'm a Polish native speaker. I want you to proofread my English text and make it sound natural and fluent—like something a native speaker would write in a casual or semi-professional context.
Keep it clear, friendly, and natural. Not too formal, but keep it serious and professional.

If the text is already fine, just reply with: 'Looks good!'
If you have suggestions, rewrite the improved version and briefly explain any important changes.

Here's the text:
" | jq -R -s)

	set prompt (echo -n $argv | jq -R -s)

	if test -x /usr/bin/security
		set token (security find-generic-password -w -s OpenAI)
	end
	if test -z "$token" && command -v pass &>/dev/null
		set token (pass show OpenAI)
	end
	set url "https://api.openai.com"

	curl -s $url/v1/chat/completions \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $token" \
		-d '{
			"model": "gpt-4o",
			"messages": [
				{
					"role": "system",
					"content": '$system'
				},
				{
					"role": "user",
					"content": '$prompt'
				}
			]
		}' | jq -r '.choices[].message.content'
end
