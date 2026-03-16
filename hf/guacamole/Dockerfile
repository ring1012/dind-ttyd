FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 安装基础组件
RUN apt update && apt install -y \
    xfce4 xfce4-goodies \
    xrdp \
    wget curl gnupg2 ca-certificates \
    openjdk-17-jre \
    tomcat9 \
    guacd \
    dbus-x11 \
    sudo \
    libnss3 libgbm1 libx11-xcb1 libxcomposite1 libxdamage1 libxfixes3 \
    libxrandr2 libatk1.0-0 libatk-bridge2.0-0 libcups2 libasound2 \
    fonts-noto-color-emoji fonts-noto \
    && apt clean

# 安装官方 Google Chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt install -y ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb

# Guacamole Webapp
RUN wget https://archive.apache.org/dist/guacamole/1.5.5/binary/guacamole-1.5.5.war \
    -O /var/lib/tomcat9/webapps/guacamole.war

RUN mkdir -p /etc/guacamole

# guacamole config
RUN echo "guacd-hostname: localhost" > /etc/guacamole/guacamole.properties && \
    echo "guacd-port: 4822" >> /etc/guacamole/guacamole.properties && \
    echo "user-mapping: /etc/guacamole/user-mapping.xml" >> /etc/guacamole/guacamole.properties

# user mapping
RUN printf '<user-mapping>\n\
<authorize username="admin" password="admin">\n\
<connection name="desktop">\n\
<protocol>rdp</protocol>\n\
<param name="hostname">localhost</param>\n\
<param name="port">3389</param>\n\
<param name="username">user</param>\n\
<param name="password">user</param>\n\
<param name="security">rdp</param>\n\
<param name="ignore-cert">true</param>\n\
</connection>\n\
</authorize>\n\
</user-mapping>' > /etc/guacamole/user-mapping.xml


RUN apt update && apt install -y xvfb x11-utils

# Set up a new user named "user"
RUN useradd -m -u 1000 user && \
    echo "user:user" | chpasswd && \
    adduser user sudo

# XFCE startup
RUN echo -e '#!/bin/bash\n'\
'google-chrome-stable --no-sandbox --disable-dev-shm-usage &' > /home/user/.xprofile && \
    chmod +x /home/user/.xprofile

RUN echo "startxfce4" > /home/user/.xsession \
    && chown -R user:user /home/user

# Replace start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080
EXPOSE 3389

CMD ["/start.sh"]
