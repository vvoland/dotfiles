target "shell" {
  dockerfile-inline = <<EOF
FROM alpine
RUN apk add --no-cache ripgrep bash automake fish python3 git
EOF
  tags      = ["pawelgronowski465/cagent", "vlnd/cagent"]
  platforms = ["linux/amd64", "linux/arm64"]
}
