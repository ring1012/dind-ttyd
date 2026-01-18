#!/usr/bin/env bash
set -euo pipefail

echo "=== [sync-01] start pull to /config.remote and conditional overwrite ==="

REMOTE_USER="hf"
REMOTE_HOST="${server_name}"
REMOTE_DIR="/data/hf-chrome-profile"

CONFIG_DIR="/config"
REMOTE_TMP_DIR="/config.remote"
SSH_KEY="${CONFIG_DIR}/id_ed25519"

echo ">>> listing /config before sync"
ls -la "${CONFIG_DIR}" || true

# —— 写 SSH 私钥 —— #
echo ">>> writing SSH private key from env"
if [ -z "${SSH_PRIVATE_KEY:-}" ]; then
  echo "!!! SSH_PRIVATE_KEY environment variable is empty"
  exit 1
fi

mkdir -p "${CONFIG_DIR}"
echo "$SSH_PRIVATE_KEY" > "${SSH_KEY}"
chmod 600 "${SSH_KEY}"
chown abc:abc "${SSH_KEY}" 2>/dev/null || true

echo ">>> SSH key prepared"
ls -la "${CONFIG_DIR}"

SSH_CMD="ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# —— 拉取到 /config.remote —— #
echo ">>> pulling remote config into ${REMOTE_TMP_DIR}"
rm -rf "${REMOTE_TMP_DIR}" || true
mkdir -p "${REMOTE_TMP_DIR}"

rsync -az --delete \
  -e "${SSH_CMD}" \
  "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" \
  "${REMOTE_TMP_DIR}/" \
  && echo ">>> remote config pulled to ${REMOTE_TMP_DIR}" \
  || echo "!!! failed pulling remote config"

# —— 检查是否有内容 —— #
if [ "$(find "${REMOTE_TMP_DIR}" -mindepth 1 | wc -l)" -eq 0 ]; then
  echo ">>> /config.remote is empty — skipping overwrite"
else
  echo ">>> remote has content — overwriting /config"

  # 删除 /config 下除了 SSH key 之外的内容
  find "${CONFIG_DIR}" -mindepth 1 -maxdepth 1 \
    -not -name "id_ed25519" \
    -not -name "id_ed25519.pub" \
    -exec rm -rf {} \;

  # 复制 remote 内容覆盖
  rsync -az \
    "${REMOTE_TMP_DIR}/" \
    "${CONFIG_DIR}/"

  echo ">>> overwrite complete"

  # —— 修改属于 abc 用户 —— #
  echo ">>> setting ownership of /config to abc:abc"
  chown -R abc:abc "${CONFIG_DIR}"
fi

echo "===nohup02=="
nohup /custom-services.d/sync-push/run  > /dev/null 2>&1 &
echo "=== [sync-01] done ==="
