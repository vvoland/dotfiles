#!/bin/sh
set -eu

mkdir -p "$HOME/.config/systemd/user"
mkdir -p "$HOME/.config/environment.d"

cat > "$HOME/.config/systemd/user/ssh-agent.service" <<'EOF'
[Unit]
Description=SSH key agent

[Service]
Type=simple
ExecStart=/usr/bin/ssh-agent -D -a %t/ssh-agent.socket

[Install]
WantedBy=default.target
EOF

cat > "$HOME/.config/environment.d/ssh-agent.conf" <<'EOF'
SSH_AUTH_SOCK=${XDG_RUNTIME_DIR}/ssh-agent.socket
EOF

systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.service

printf '%s\n' 'Done. Log out of GDM, log back into Sway, then run:'
