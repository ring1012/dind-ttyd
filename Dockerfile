FROM docker:dind


RUN apk add --no-cache build-base cmake  json-c-dev  zlib-dev  build-base cmake git json-c-dev nano openssl-dev libuv-dev  linux-headers sudo


RUN ssh-keygen -A
RUN apk add --no-cache openssh

RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config


RUN /usr/sbin/sshd


RUN mkdir -p /root/data
RUN cd /root/data
RUN git clone https://github.com/warmcat/libwebsockets.git
RUN cd libwebsockets
RUN mkdir build
RUN cd build
RUN cmake -DLWS_BUILD_TESTAPPS=OFF -DLWS_WITH_LIBUV=ON -DCMAKE_INSTALL_PREFIX=/usr ..
RUN make
RUN make install

RUN cd /root/data
RUN wget https://github.com/tsl0922/ttyd/archive/refs/tags/1.6.3.zip
RUN unzip 1.6.3.zip
RUN cd ttyd-1.6.3
RUN mkdir build
RUN cd build
RUN cmake ..
RUN make
RUN make install



RUN adduser -D admin && echo "admin" | chpasswd


RUN addgroup admin wheel


RUN sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers


COPY ENTRYPOINT.sh /ENTRYPOINT.sh

RUN chmod 755 /ENTRYPOINT.sh


CMD ["/ENTRYPOINT.sh"]