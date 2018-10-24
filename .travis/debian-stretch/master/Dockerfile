FROM debian:stretch

ARG hostname
ARG saltenv
ARG pillarenv
ARG log_level
# "" == latest
ARG salt_ver=""

COPY envoy /srv/envoy
COPY .travis/entrypoint_master_run.sh /opt/
COPY .travis/scan_events.py /opt/
COPY .travis/config/master.conf /etc/salt/master.d/master.conf
COPY .travis/config/reactor_master.conf /etc/salt/master.d/reactor.conf
COPY .travis/config/supervisord_master.conf /etc/supervisor/conf.d/supervisord.conf
COPY .travis/pillar /srv/pillar
COPY .travis/reactor /srv/reactor
COPY .travis/salt/dev/top.sls /srv/envoy/salt/base/
COPY .travis/config/no_daemon_env /etc/default/salt-master

RUN echo $(grep $(hostname) /etc/hosts | cut -f1) $hostname >> /etc/hosts && \
    apt-get update && \
    apt-get install -y curl supervisor procps && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -n -M -N -X stable $salt_ver && \
    ln -s /srv/envoy/salt /srv/salt && \
# workaround for (needed only when installed via Dockerfile)
# https://github.com/saltstack/salt/issues/37056
    rm -rf /var/run/salt/master/master_event_pub.ipc && \
    rm -rf /var/run/salt/master/master_event_pull.ipc

EXPOSE 4505:4505 4506:4506

ENV SALTENV=$saltenv
ENV PILLARENV=$pillarenv
ENV LOG_LEVEL=$log_level
ENTRYPOINT [ "/opt/entrypoint_master_run.sh" ]
