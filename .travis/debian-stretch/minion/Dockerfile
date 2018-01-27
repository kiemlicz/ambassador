FROM debian:stretch

# "" == latest
ARG SALT_VER=""

COPY .travis/entrypoint_minion_run.sh /opt/
COPY .travis/config/minion.conf /etc/salt/minion.d/minion.conf
COPY .travis/config/supervisord_minion.conf /etc/supervisor/conf.d/supervisord.conf

RUN apt-get update && \
    apt-get install -y curl supervisor

ENTRYPOINT ["/opt/entrypoint_minion_run.sh"]
CMD [ "$SALT_VER" ]
