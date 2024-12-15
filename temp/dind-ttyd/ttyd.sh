#/bin/sh
sudo apt update
sudo apt install libuv1-dev  libev4 libev-dev -y
wget http://thd.us.kg:8880/ttyd_1.6.3-1_amd64.deb
dpkg -i ttyd_1.6.3-1_amd64.deb
sudo timedatectl set-timezone Asia/Shanghai



