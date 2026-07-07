#!/usr/bin/env bash

set -euo pipefail

#######################################
# Global config
#######################################

KASMVNC_VERSION="1.4.0"

KASMVNC_DEB="kasmvncserver_jammy_${KASMVNC_VERSION}_amd64.deb"

KASMVNC_URL="https://github.com/kasmtech/KasmVNC/releases/download/v${KASMVNC_VERSION}/${KASMVNC_DEB}"

CHROME_DEB="google-chrome-stable_current_amd64.deb"

CHROME_URL="https://dl.google.com/linux/direct/${CHROME_DEB}"

DISPLAY_NUM=":1"

VNC_PORT="8444"

WORKDIR="/tmp/kasm-installer"


#######################################
# Color
#######################################

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"


#######################################
# Log
#######################################

log_info()
{
    echo -e "${GREEN}[INFO]${RESET} $*"
}


log_warn()
{
    echo -e "${YELLOW}[WARN]${RESET} $*"
}


log_error()
{
    echo -e "${RED}[ERROR]${RESET} $*"
}


#######################################
# Utils
#######################################

command_exists()
{
    command -v "$1" >/dev/null 2>&1
}


download()
{
    local url="$1"
    local file="$2"

    if [ -f "$file" ]; then
        log_info "$file already exists"
        return
    fi

    wget -O "$file" "$url"
}


#######################################
# Banner
#######################################

banner()
{
cat <<EOF

========================================

 KasmVNC + XFCE + Chrome Installer

 Ubuntu 22.04

========================================

EOF
}


#######################################
# Check root
#######################################

check_root()
{
    if [ "$(id -u)" != "0" ]; then
        log_error "Please run as root"
        exit 1
    fi
}


#######################################
# Check OS
#######################################

check_os()
{
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect OS"
        exit 1
    fi


    . /etc/os-release


    if [ "$ID" != "ubuntu" ]; then
        log_error "Only Ubuntu supported"
        exit 1
    fi


    if [[ "$VERSION_ID" != "22.04" ]]; then
        log_warn "This script targets Ubuntu 22.04"
    fi


    log_info "Detected Ubuntu $VERSION_ID"
}



#######################################
# Install dependencies
#######################################

install_dependencies()
{
    log_info "Installing dependencies"


    apt update


    apt install -y \
        xfce4 \
        xfce4-goodies \
        dbus-x11 \
        xauth \
        x11-xserver-utils \
        wget \
        curl \
        ca-certificates \
        fonts-dejavu \
        expect \
        unzip


    mkdir -p "$WORKDIR"
}



#######################################
# Install Chrome
#######################################

install_google_chrome()
{
    if command_exists google-chrome; then
        log_info "Chrome already installed"
        return
    fi


    log_info "Downloading Chrome"


    cd "$WORKDIR"


    download \
        "$CHROME_URL" \
        "$CHROME_DEB"


    log_info "Installing Chrome"


    apt install -y "./$CHROME_DEB"
}



#######################################
# Install KasmVNC
#######################################

install_kasmvnc()
{
    if command_exists kasmvncserver; then
        log_info "KasmVNC already installed"
        return
    fi


    cd "$WORKDIR"


    log_info "Downloading KasmVNC"


    download \
        "$KASMVNC_URL" \
        "$KASMVNC_DEB"


    log_info "Installing KasmVNC"


    apt install -y "./$KASMVNC_DEB"
}



#######################################
# Init KasmVNC
#######################################
init_kasmvnc()
{

    log_info "Initialize KasmVNC"


    if [ ! -f /root/.vnc/kasmvnc.yaml ]; then


        read -rsp "Enter KasmVNC password: " PASS
        echo


        read -rsp "Verify password: " PASS2
        echo


        if [ "$PASS" != "$PASS2" ]; then
            error "Password mismatch"
            exit 1
        fi



        #
        # 临时启动一次，让KasmVNC初始化
        #

        echo -e "${PASS}\n${PASS}" \
        | kasmvncserver :1 \
            >/tmp/kasm-init.log 2>&1 || true



        sleep 2



        kasmvncserver -kill :1 \
            >/dev/null 2>&1 || true



    fi


    log_info "KasmVNC initialized"






    ###################################
    # xstartup
    ###################################

    cat >/root/.vnc/xstartup <<'EOF'

#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

exec xfce4-session

EOF


    chmod +x /root/.vnc/xstartup



    ###################################
    # KasmVNC config
    ###################################

    cat >/root/.vnc/kasmvnc.yaml <<EOF

network:
  interface: 0.0.0.0
  websocket_port: ${VNC_PORT}
  protocol: http
  ssl:
    require_ssl: false



EOF


    log_info "KasmVNC initialized"

}

#######################################
# Create KasmVNC password
#######################################

#######################################
# Create KasmVNC password
#######################################

create_kasm_password()
{

    if [ -f /root/.kasmpasswd ]; then
        log_info "KasmVNC password already exists"
        return
    fi


    echo

    read -rsp "Enter KasmVNC password: " PASS
    echo

    read -rsp "Verify password: " PASS2
    echo


    if [ "$PASS" != "$PASS2" ]; then
        log_error "Password mismatch"
        exit 1
    fi



    mkdir -p /root/.vnc



    #
    # 创建 KasmVNC 用户密码
    #
    echo -e "${PASS}\n${PASS}" \
        | kasmvncpasswd \
            /root/.vnc/passwd



    chmod 600 /root/.vnc/passwd



    #
    # 创建 KasmVNC web 登录密码
    #
    mkdir -p /root



    echo -n "$PASS" \
        > /root/.kasmpasswd



    chmod 600 /root/.kasmpasswd



    log_info "KasmVNC password created"

}




#######################################
# Configure Chrome launcher
#######################################

configure_chrome()
{

    log_info "Configure Chrome launcher"


    local desktop


    if [ -f /usr/share/applications/google-chrome.desktop ]; then

        desktop="/usr/share/applications/google-chrome.desktop"

    else

        log_warn "Chrome desktop file not found"
        return

    fi



    cp "$desktop" \
       "${desktop}.bak"



    sed -i \
    's#Exec=.*#Exec=/usr/bin/google-chrome-stable --no-sandbox --disable-gpu --disable-dev-shm-usage --disable-software-rasterizer %U#g' \
    "$desktop"



    log_info "Chrome launcher fixed"

}




#######################################
# Create KasmVNC start script
#######################################

create_start_script()
{

cat >/usr/local/bin/kasm-chrome.sh <<'EOF'
#!/bin/bash

set -e


export HOME=/root
export USER=root
export DISPLAY=:1

export XDG_RUNTIME_DIR=/tmp/runtime-root


mkdir -p "$XDG_RUNTIME_DIR"

chmod 700 "$XDG_RUNTIME_DIR"



# kill old session

kasmvncserver -kill :1 \
    >/dev/null 2>&1 || true



exec kasmvncserver :1 \
    -fg \
    -localhost no \
    -SecurityTypes None \
    -geometry 1920x1080 \
    -depth 24

EOF



chmod +x /usr/local/bin/kasm-chrome.sh


log_info "Created kasm start script"

}





#######################################
# Create systemd service
#######################################

create_systemd_service()
{

cat >/etc/systemd/system/kasm-chrome.service <<'EOF'


[Unit]

Description=KasmVNC Chrome Desktop

After=network.target



[Service]

Type=simple

User=root

Environment=HOME=/root

ExecStart=/usr/local/bin/kasm-chrome.sh

Restart=always

RestartSec=5



[Install]

WantedBy=multi-user.target

EOF



systemctl daemon-reload


systemctl enable kasm-chrome


log_info "Created systemd service"

}




#######################################
# Install cloudflared
#######################################

install_cloudflared()
{

    if command_exists cloudflared; then
        log_info "cloudflared already installed"
    else

        log_info "Installing cloudflared"


        wget -q \
        https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
        -O /tmp/cloudflared.deb


        apt install -y /tmp/cloudflared.deb

    fi



    echo

    read -rp \
    "Install Cloudflare Tunnel? (y/N): " CF_ENABLE



    if [[ "$CF_ENABLE" != "y" ]]; then

        log_warn "Skip Cloudflare Tunnel"

        return

    fi



    read -rp \
    "Enter Cloudflare Tunnel Token: " CF_TOKEN



    if [ -z "$CF_TOKEN" ]; then

        log_warn "Empty token, skip"

        return

    fi



    cloudflared service uninstall \
        >/dev/null 2>&1 || true



    cloudflared service install "$CF_TOKEN"



    systemctl enable cloudflared

    systemctl restart cloudflared



    log_info "Cloudflare Tunnel installed"

}





#######################################
# Verify
#######################################

verify_installation()
{

    echo

    echo "============== VERIFY =============="


    if command_exists google-chrome; then
        echo "OK Chrome"
    else
        echo "FAIL Chrome"
    fi



    if command_exists kasmvncserver; then
        echo "OK KasmVNC"
    else
        echo "FAIL KasmVNC"
    fi



    if systemctl is-enabled kasm-chrome >/dev/null; then
        echo "OK systemd"
    else
        echo "FAIL systemd"
    fi



    systemctl restart kasm-chrome



    sleep 5



    if ss -lnt | grep -q ":8444"; then

        echo "OK Port 8444"

    else

        echo "FAIL Port 8444"

    fi



    echo

}





#######################################
# Success
#######################################

success()
{

cat <<EOF


=====================================

 Installation Finished


KasmVNC:

http://YOUR_SERVER_IP:8444


Service:

systemctl status kasm-chrome


Restart:

systemctl restart kasm-chrome


=====================================


EOF

}





#######################################
# Main
#######################################

main()
{

    banner


    check_root

    check_os


    install_dependencies


    install_google_chrome


    install_kasmvnc


    init_kasmvnc


    configure_chrome


    create_start_script


    create_systemd_service


    install_cloudflared


    verify_installation


    success

}



main "$@"
