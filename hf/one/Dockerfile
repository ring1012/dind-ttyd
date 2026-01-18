# ---------- 基础镜像 ----------
# syntax=docker/dockerfile:1

FROM ubuntu:22.04


# environment settings
ARG DEBIAN_FRONTEND="noninteractive"


# ---------- 设置环境 ----------
ENV LANG=C.UTF-8

# ---------- 安装常用工具 ----------
RUN apt-get update && apt-get install -y \
    git curl wget zip unzip net-tools procps \
    build-essential software-properties-common  \
    cmake git libjson-c-dev ttyd vim cron\
    && rm -rf /var/lib/apt/lists/*


# ---------- 安装开发工具 ----------
# 1. Java
RUN apt-get update && apt-get install -y openjdk-17-jdk

# 2. Python3 + pip + venv
RUN apt-get install -y python3 python3-pip python3-venv

# 3. Node.js (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs

# ---------- 安装 nginx 和 ttyd ----------
RUN apt-get update && apt-get install -y nginx

# Set the working directory to the user's home directory
WORKDIR /config
COPY package.json /config/
RUN wget http://forever.19930105.xyz:8880/x86_64/gotty_v1.6.0_linux_amd64.tar.gz
RUN tar -xzvf gotty_v1.6.0_linux_amd64.tar.gz



# ---------- 添加 nginx 配置 ----------
RUN rm /etc/nginx/sites-enabled/default
COPY nginx-ttyd.conf /etc/nginx/sites-available/ttyd.conf
RUN ln -s /etc/nginx/sites-available/ttyd.conf /etc/nginx/sites-enabled/ttyd.conf

# ---------- 添加启动脚本 ----------
COPY start.sh /start.sh
RUN chmod +x /start.sh
COPY app.js ./
COPY huan-init /huan-init
RUN chmod +x /huan-init



# ---------- 容器启动命令 ----------
ENTRYPOINT ["/start.sh"]
