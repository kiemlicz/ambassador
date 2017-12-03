FROM debian:stretch
COPY .travis/entrypoint_minion_run.sh /opt/
COPY .travis/config/minion.conf /etc/salt/minion.d/minion.conf
COPY .travis/config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN apt-get update && \
    apt-get install -y curl supervisor && \
    curl -L https://bootstrap.saltstack.com | sh

ENTRYPOINT ["/opt/entrypoint_minion_run.sh"]
