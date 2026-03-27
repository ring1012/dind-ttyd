#!/bin/bash
set -e

export CATALINA_BASE=/var/lib/tomcat9
export CATALINA_HOME=/usr/share/tomcat9

echo "Start virtual X display"
Xvfb :99 -ac -screen 0 1920x1080x24 &
export DISPLAY=:99

echo "starting guacd"
/usr/sbin/guacd &

echo "starting xrdp"
/usr/sbin/xrdp-sesman &
/usr/sbin/xrdp &

echo "starting tomcat"
/usr/share/tomcat9/bin/catalina.sh run
