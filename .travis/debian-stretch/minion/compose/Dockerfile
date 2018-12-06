FROM debian:stretch

# "" == latest
ARG salt_ver=""

COPY .travis/entrypoint_minion_run.sh /opt/
COPY .travis/config/minion.conf /etc/salt/minion.d/minion.conf
COPY .travis/config/supervisord_minion.conf /etc/supervisor/conf.d/supervisord.conf
COPY .travis/config/no_daemon_env /etc/default/salt-minion

RUN apt-get update && \
    apt-get install -y curl supervisor procps && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -n -X stable $salt_ver

ENTRYPOINT ["/opt/entrypoint_minion_run.sh"]
