FROM debian:stretch
COPY envoy /srv/envoy
COPY .travis/entrypoint_master_run.sh /opt/
COPY .travis/config/master.conf /etc/salt/master.d/master.conf
COPY .travis/config/master_reactor.conf /etc/salt/master.d/reactor.conf
COPY .travis/reactor /srv/reactor
COPY .travis/pillar /srv/pillar
RUN apt-get update && \
    apt-get install -y curl && \
    ln -s /srv/envoy/salt /srv/salt && \
    ln -s /srv/envoy/extensions /srv/salt_ext \
    curl -L https://bootstrap.saltstack.com | sh

ARG SALTENV
ARG LOG_LEVEL

ENTRYPOINT ["/opt/entrypoint_master_run.sh"]
