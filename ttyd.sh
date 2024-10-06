#!/bin/sh
apk add --no-cache build-base cmake  json-c-dev  zlib-dev  build-base cmake git json-c-dev nano git openssl-dev libuv-dev  linux-headers sudo


ssh-keygen -A
apk add --no-cache openssh

sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config openrc


/usr/sbin/sshd


mkdir -p /root/data
cd /root/data
git clone https://github.com/warmcat/libwebsockets.git
cd libwebsockets
mkdir build
cd build
cmake -DLWS_BUILD_TESTAPPS=OFF -DLWS_WITH_LIBUV=ON -DCMAKE_INSTALL_PREFIX=/usr ..
make
make install

cd /root/data
wget https://github.com/tsl0922/ttyd/archive/refs/tags/1.6.3.zip
unzip 1.6.3.zip
cd ttyd-1.6.3
mkdir build
cd build
cmake ..
make
make install
nohup ttyd -p 2086 --check-origin=false /bin/login > /dev/null 2>&1 &


adduser -D admin && echo "admin:admin" | chpasswd


addgroup admin wheel


sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers


