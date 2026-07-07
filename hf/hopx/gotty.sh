#!/bin/bash

set -e


#######################################
# Config
#######################################

GOTTY_VERSION="v1.8.0"

GOTTY_URL="https://github.com/sorenisanerd/gotty/releases/download/${GOTTY_VERSION}/gotty_v1.8.0_linux_amd64.tar.gz"

INSTALL_PATH="/usr/bin/gotty"

TMP_DIR="/tmp/gotty-install"



#######################################
# Color
#######################################

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"



log()
{
    echo -e "${GREEN}[INFO]${RESET} $*"
}


error()
{
    echo -e "${RED}[ERROR]${RESET} $*"
}



#######################################
# Check root
#######################################

check_root()
{
    if [ "$(id -u)" != "0" ]; then
        error "Please run as root"

        exit 1
    fi
}



#######################################
# Install gotty
#######################################

install_gotty()
{

    if [ -f "$INSTALL_PATH" ]; then

        log "gotty already exists"

        return

    fi


    mkdir -p "$TMP_DIR"

    cd "$TMP_DIR"



    log "Downloading gotty"

    wget -O gotty.tar.gz "$GOTTY_URL"



    log "Extracting"

    tar -zxvf gotty.tar.gz



    if [ ! -f gotty ]; then

        error "gotty binary not found"

        exit 1

    fi



    mv gotty "$INSTALL_PATH"

    chmod +x "$INSTALL_PATH"



    log "Installed: $INSTALL_PATH"

}



#######################################
# Start gotty
#######################################

start_gotty()
{

    if ! command -v gotty >/dev/null 2>&1; then

        error "gotty not installed"

        exit 1

    fi



    read -rp "Username: " USERNAME


    read -rsp "Password: " PASSWORD

    echo



    # kill old process

    pkill -f "gotty.*2086" \
        >/dev/null 2>&1 || true



    log "Starting gotty"



    nohup gotty \
        -w \
        -c "${USERNAME}:${PASSWORD}" \
        -p 2086 \
        --ws-origin=.* \
        bash \
        >/dev/null 2>&1 &



    sleep 2



    if pgrep -f "gotty.*2086" >/dev/null; then

        log "gotty started"

    else

        error "gotty start failed"

        exit 1

    fi

}



#######################################
# Main
#######################################

main()
{

    check_root

    install_gotty

    start_gotty



    echo

    echo "================================"

    echo " Gotty started"

    echo

    echo "Port: 2086"

    echo

    echo "Command:"

    echo "http://SERVER_IP:2086"

    echo

    echo "================================"

}


main
