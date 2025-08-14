function cagent
    export ANTHROPIC_API_KEY=$(security find-generic-password -w -s Anthropic)
    export OPENAI_API_KEY=$(security find-generic-password -w -s OpenAI)
    #CAGENT_MODELS_GATEWAY=https://gw.docker.com/models
    ~/c/cagent/dist/cagent $argv
end
