#!/usr/bin/env bash
set -euo pipefail

echo "=== [sync-02] start periodic config push ==="

REMOTE_USER="hf"
REMOTE_HOST="${server_name}"
REMOTE_DIR="/data/hf-chrome-profile"
CONFIG_DIR="/config"
SSH_KEY="${CONFIG_DIR}/id_ed25519"
SSH_CMD="ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# 无限循环推送
while true; do
  echo ">>> [sync-02] sleeping 300s"
  sleep 300

  if [ -d "${CONFIG_DIR}" ]; then
    echo ">>> [sync-02] pushing entire /config to remote"
    rsync -az --delete \
      -e "${SSH_CMD}" \
      "${CONFIG_DIR}/" \
      "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" \
      && echo ">>> [sync-02] push succeeded" \
      || echo "!!! [sync-02] push failed"
  else
    echo "!!! [sync-02] /config missing — skip"
  fi
done
