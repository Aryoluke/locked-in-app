#!/usr/bin/env bash
# LOCKED IN - Server deploy script for Linux / Raspberry Pi (bash)
# Usage:  sudo ./deploy-linux.sh <optional-docker? no - plain systemd>

set -euo pipefail

APP_DIR="/opt/lockedin"
SERVICE="lockedin"

# ---- 1. Install system + Python deps -------------------------------------
echo "[1/5] Installing system packages..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-venv python3-pip uvicorn

# ---- 2. Copy code ----------------------------------------------------------
echo "[2/5] Deploying code to $APP_DIR"
sudo mkdir -p "$APP_DIR"
sudo rsync -a --delete \
  "$(dirname "$0")/../server/" "$APP_DIR/server/"

# ---- 3. Python venv --------------------------------------------------------
echo "[3/5] Creating venv + installing requirements"
cd "$APP_DIR/server"
sudo python3 -m venv .venv
sudo ./.venv/bin/pip install --upgrade pip
sudo ./.venv/bin/pip install -r requirements.txt

# ---- 4. systemd unit --------------------------------------------------------
echo "[4/5] Installing systemd unit"
sudo tee /etc/systemd/system/$SERVICE.service > /dev/null <<EOF
[Unit]
Description=LOCKED IN fitness/life app server
After=network.target

[Service]
WorkingDirectory=$APP_DIR/server
ExecStart=$APP_DIR/server/.venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000 --workers 1
Restart=always
RestartSec=5
# Insert your strong secret here (or put it in .env):
Environment=SECRET_KEY=change-me-to-a-long-random-string
Environment=PORT=8000
User=root
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now $SERVICE

# ---- 5. Daily backup --------------------------------------------------------
echo "[5/5] Scheduling daily backup (cron)"
(crontab -l 2>/dev/null; echo "0 3 * * * cp $APP_DIR/server/locked_in.db $APP_DIR/backups/locked_in_\$(date +\\%Y\\%m\\%d).db") | crontab -

echo ""
echo "LOCKED IN deployed. Health check:"
sleep 2
curl -s http://127.0.0.1:8000/health && echo ""
echo "API docs:        http://<this-server-ip>:8000/docs"
echo "Logs:            journalctl -u $SERVICE -f"
echo ""
echo "Next: put this behind Caddy/HTTPS (see scripts/Caddyfile) or a Tailscale"
echo "tailnet, then point the Flutter app at your server URL."
