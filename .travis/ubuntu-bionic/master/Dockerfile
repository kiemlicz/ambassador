FROM ubuntu:bionic

ARG saltenv
ARG pillarenv
ARG log_level
ARG salt_ver

COPY envoy /srv/envoy
COPY .travis/entrypoint_master_run.sh /opt/
COPY .travis/scan_events.py /opt/
COPY .travis/config/master.conf /etc/salt/master.d/master.conf
COPY .travis/config/autosign.conf /etc/salt/autosign.conf
COPY .travis/config/reactor_$pillarenv.conf /etc/salt/master.d/reactor.conf
COPY .travis/config/supervisord_master.conf /etc/supervisor/conf.d/supervisord.conf
COPY .travis/config/reactor/$pillarenv /srv/reactor
COPY .travis/pillar/$pillarenv /srv/pillar
COPY .travis/salt/dev/top.sls /srv/envoy/salt/base/
COPY .travis/salt/dev/_orchestrate /srv/envoy/salt/dev/_orchestrate
COPY .travis/config/no_daemon_env /etc/default/salt-master

RUN apt-get update && apt-get remove -y gnupg iproute2 && \
    apt-get install -y --reinstall gnupg2 && \
    apt-get install -y curl dirmngr python-pip supervisor procps iproute2 && \
    chmod 600 /etc/salt/autosign.conf && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -n -d -M -N -X $salt_ver && \
    ln -s /srv/envoy/salt /srv/salt

EXPOSE 4505:4505 4506:4506

ENV SALTENV=$saltenv
ENV LOG_LEVEL=$log_level
ENTRYPOINT [ "/opt/entrypoint_master_run.sh" ]
