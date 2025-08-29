function claude
  set system "You are an assistant of software engineer working primarily with Go language on Linux. You are prompted from a CLI terminal. Be succint and direct with your help. Prefer to output code/commands directly without text if possible. When outputting code, don't put triple backticks markdown before and after code."
  set prompt (echo -n $argv | jq -R -s)

  if test -x /usr/bin/security
    set token (security find-generic-password -w -s Anthropic)
  end
  if test -z "$token" -a -n "$ANTHROPIC_API_KEY"
    set token $ANTHROPIC_API_KEY
  end
  if test -z "$token" && command -v pass &>/dev/null
    set token (pass show Anthropic)
  end

  set url "https://api.anthropic.com"
  set model "claude-sonnet-4-20250514"

  set payload (jq -n \
    --arg model $model \
    --arg system $system \
    --arg prompt $prompt \
    --argjson stream true '
  {
    model: $model,
    max_tokens: 16000,
    system: $system,
    stream: $stream,
    messages: [
      { role: "user", content: $prompt }
    ]
  }')

  curl -sN $url/v1/messages \
    -H "Content-Type: application/json" \
    -H "Accept: text/event-stream" \
    -H "x-api-key: $token" \
    -H "anthropic-version: 2023-06-01" \
    -d "$payload" \
  | while read -l line
      if string match -rq '^data: ' -- $line
        set json (string sub -s 7 -- $line)
        echo -n $json | jq -jr '
          if .type == "content_block_delta" and .delta.type == "text_delta"
            then .delta.text
          else empty
          end
        '
      end
    end

  echo # trailing newline
end
