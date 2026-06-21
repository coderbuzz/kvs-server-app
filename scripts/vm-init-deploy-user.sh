#!/usr/bin/env bash
set -euo pipefail

DEPLOY_USER="${1:-deploy}"

echo "=== KVS Server App — VM Initialization ==="
echo ""

if id "$DEPLOY_USER" &>/dev/null; then
  echo "[SKIP] User '$DEPLOY_USER' already exists"
else
  sudo useradd -m -s /bin/bash "$DEPLOY_USER"
  echo "[OK] User '$DEPLOY_USER' created"
fi

if groups "$DEPLOY_USER" | grep -qF docker; then
  echo "[SKIP] User '$DEPLOY_USER' already in docker group"
else
  sudo usermod -aG docker "$DEPLOY_USER"
  echo "[OK] Added '$DEPLOY_USER' to docker group"
fi

if [ ! -d "/home/$DEPLOY_USER/.ssh" ]; then
  sudo -u "$DEPLOY_USER" mkdir -p "/home/$DEPLOY_USER/.ssh"
  sudo -u "$DEPLOY_USER" chmod 700 "/home/$DEPLOY_USER/.ssh"
fi

KEY_PATH="/home/$DEPLOY_USER/.ssh/id_ed25519"
if [ -f "$KEY_PATH" ]; then
  echo "[SKIP] SSH key already exists at $KEY_PATH"
else
  sudo -u "$DEPLOY_USER" ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "deploy@$(hostname)" -q
  echo "[OK] SSH key generated"
fi

PUBKEY=$(sudo cat "/home/$DEPLOY_USER/.ssh/id_ed25519.pub")
if [ -f "/home/$DEPLOY_USER/.ssh/authorized_keys" ] && grep -qF "$PUBKEY" "/home/$DEPLOY_USER/.ssh/authorized_keys" 2>/dev/null; then
  echo "[SKIP] Public key already in authorized_keys"
else
  echo "$PUBKEY" | sudo -u "$DEPLOY_USER" tee -a "/home/$DEPLOY_USER/.ssh/authorized_keys" > /dev/null
  sudo -u "$DEPLOY_USER" chmod 600 "/home/$DEPLOY_USER/.ssh/authorized_keys"
  echo "[OK] Public key added to authorized_keys"
fi

echo ""
echo "============================================"
echo "  Setup complete"
echo "============================================"
echo ""
echo "Copy the private key below to GitHub Secrets:"
echo ""
echo "  Name:  DEPLOY_SSH_KEY"
echo "  Repo:  coderbuzz/kvs-server-app"
echo ""
echo "--- BEGIN PRIVATE KEY ---"
sudo cat "$KEY_PATH"
echo "--- END PRIVATE KEY ---"
echo ""
echo "Also add these secrets to the repo:"
echo ""
echo "  DEPLOY_HOST  = <VM IP address>"
echo "  ACCESS_TOKEN = <your KVS bearer token>"
echo "  DOMAIN       = <e.g. kvs.example.com>"
echo ""
echo "User '$DEPLOY_USER' will be reused for future apps on the same VM."
