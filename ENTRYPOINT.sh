#!/bin/sh
#docker run -d --privileged --restart always -e CF_TOKEN="YOUR_TOKEN" registry.cn-hangzhou.aliyuncs.com/ring1012/dind-ttyd:2024-10-06

docker run -d --restart always --name cloudflare_tunnel  cloudflare/cloudflared:latest  tunnel --no-autoupdate run --token $CF_TOKEN

nohup ttyd -p 2086 --check-origin=false /bin/login > /dev/null 2>&1 &