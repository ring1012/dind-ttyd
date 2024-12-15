FROM v2fly/v2fly-core:latest

RUN apk update

RUN apk add nginx curl

COPY nginx.conf /etc/nginx/nginx.conf
#RUN wget https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh 
#RUN chmod 755 install-release.sh
#RUN sh install-release.sh


COPY ali.json /ali.json
COPY entry.sh /entry.sh

RUN chmod 755 /entry.sh
RUN chmod 755 /ali.json

#RUN curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb  

#RUN dpkg -i cloudflared.deb 
RUN curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/bin/cloudflared
RUN chmod 755  /usr/bin/cloudflared

ENTRYPOINT ["/entry.sh"]

