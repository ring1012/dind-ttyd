#!/bin/sh
nginx -g "daemon off;" &
cloudflared service install eyJhIjoiMTFiMmE0ZTU4NDhlYmI0ZjQ0NWI2NWI1YTljZDhiMTciLCJ0IjoiNDI0N2VlOGUtMWVjMC00YTAyLWFjNWEtZmM3ZGM1NjlmMDJiIiwicyI6Ik1qVmpZVEpoWlRFdFpqYzROeTAwTkRFeExXSmlPREV0TlRReE5UaGpOR0ZoWXpNdyJ9
/etc/init.d/cloudflared start
v2ray run --config /ali.json > /dev/null
