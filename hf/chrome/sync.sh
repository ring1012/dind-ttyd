#!/bin/bash
set -e

# 远端 VPS 配置
REMOTE_USER=hf
REMOTE_HOST=snow.19930105.xyz
REMOTE_DIR=/data/hf-chrome-profile

# 同步的本地目录
SYNC_SRC=/config/.config/google-chrome/
SYNC_DST=${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
ls -la /config
mv /config/id_ed25519 /config/id_ed25519.bak
cp /config/id_ed25519.bak /config/id_ed25519
chown abc:abc /config/id_ed25519 2>/dev/null || true
chmod 600 /config/id_ed25519
ls -la /config
# SSH 指令及选项
SSH_CMD="ssh -i /config/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# 1) 初次启动：若本地没有 Default profile，则从 VPS 拉一次
if [ ! -d "/config/.config/google-chrome/Default" ]; then
  echo "[sync] pulling chrome profile from VPS"

  rsync -az \
    -e "${SSH_CMD}" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" \
    "${SYNC_SRC}"
fi

# 2) 启动镜像原来的 init 逻辑（Chrome / noVNC 等）


# 3) 周期性推送增量变化到 VPS（每 5 分钟）
while true; do
  sleep 300
  echo "[sync] pushing chrome profile to VPS"

  rsync -az --delete \
    -e "${SSH_CMD}" \
    "${SYNC_SRC}" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
done
