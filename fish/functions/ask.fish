function ask --wraps='cagent run ~/cagents/ask.yaml' --description 'alias ask=cagent run ~/cagents/ask.yaml'
    TELEMETRY_ENABLED=false cagent run --yolo ~/cagents/ask.yaml $argv
end
