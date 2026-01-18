# syntax=docker/dockerfile:1

FROM linuxserver/chrome:latest


# ---- 强制 build 阶段 DNS（对 apt / nslookup 有效）----
#RUN printf "nameserver 8.8.8.8\nnameserver 8.8.4.4\n" > /etc/resolv.conf

RUN apt update && \
    apt install -y rsync openssh-client net-tools lsof dnsutils && \
    rm -rf /var/lib/apt/lists/*

# ---- runtime 再写一次（防止 baseimage 覆盖）----
#RUN printf "nameserver 8.8.8.8\nnameserver 8.8.4.4\noptions timeout:2 attempts:2\n" \
 #   > /etc/resolv.conf

# 复制同步脚本到正确位置
# 01 脚本放到 custom-cont-init.d
# 02 脚本放到 custom-services.d/sync-push/run（作为后台服务）
COPY 01_pull_from_remote.sh /custom-cont-init.d/01_pull_from_remote.sh
COPY 02_push_to_remote.sh /custom-services.d/sync-push/run
COPY 02_audio.sh /config/.xprofile
RUN chmod +x /config/.xprofile


# 给脚本加执行权限
RUN chmod +x /custom-cont-init.d/01_pull_from_remote.sh \
    && chmod +x /custom-services.d/sync-push/run


# 指定 ENTRYPOINT 直接运行同步脚本


EXPOSE 3000

VOLUME /config

