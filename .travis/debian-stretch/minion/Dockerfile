FROM debian:stretch

# "" == latest
ARG salt_ver=""

COPY .travis/entrypoint_minion_run.sh /opt/
COPY .travis/config/minion.conf /etc/salt/minion.d/minion.conf
COPY .travis/config/supervisord_minion.conf /etc/supervisor/conf.d/supervisord.conf

RUN apt-get update && \
    apt-get install -y curl supervisor procps

ENTRYPOINT ["/opt/entrypoint_minion_run.sh"]
CMD [ "$salt_ver" ]
