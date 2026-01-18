#!/bin/bash
# ---------- 启动 ttyd ----------
# 后台运行，绑定 0.0.0.0，base-path /ttyd，工作目录 /data
cd /config

# ---------- 启动 nginx ----------
#nginx -g "daemon off;"
nginx
nohup sh -c 'sleep 60; /huan-init' >/tmp/huan-init.log 2>&1 &
/config/gotty -w -c $username:$password -p 7860   --ws-origin=".*" bash
