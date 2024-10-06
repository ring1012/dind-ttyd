FROM docker:dind

COPY ttyd.sh /ttyd.sh
COPY ENTRYPOINT.sh /ENTRYPOINT.sh

RUN chmod 755 /ttyd.sh 
RUN chmod 755 /ENTRYPOINT.sh

RUN /ttyd.sh 


CMD ["/ENTRYPOINT.sh"]