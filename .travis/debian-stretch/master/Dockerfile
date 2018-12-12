FROM debian:stretch

ARG saltenv
ARG pillarenv
ARG log_level
ARG kubectl_ver
# "" == latest
ARG salt_ver=""

COPY envoy /srv/envoy
COPY .travis/entrypoint_master_run.sh /opt/
COPY .travis/scan_events.py /opt/
COPY .travis/config/master.conf /etc/salt/master.d/master.conf
COPY .travis/config/autosign.conf /etc/salt/autosign.conf
COPY .travis/config/reactor_master.conf /etc/salt/master.d/reactor.conf
COPY .travis/config/supervisord_master.conf /etc/supervisor/conf.d/supervisord.conf
COPY .travis/pillar /srv/pillar
COPY .travis/reactor /srv/reactor
COPY .travis/salt/dev/top.sls /srv/envoy/salt/base/
COPY .travis/salt/dev/_orchestrate /srv/envoy/salt/dev/_orchestrate
COPY .travis/config/no_daemon_env /etc/default/salt-master
COPY .travis/k8s /opt/k8s

RUN apt-get update && \
    apt-get install -y curl supervisor procps && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$kubectl_ver/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/bin/ && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -n -M -N -X stable $salt_ver && \
    ln -s /srv/envoy/salt /srv/salt

EXPOSE 4505:4505 4506:4506

VOLUME /etc/kubernetes

ENV SALTENV=$saltenv
ENV PILLARENV=$pillarenv
ENV LOG_LEVEL=$log_level
ENTRYPOINT [ "/opt/entrypoint_master_run.sh" ]
