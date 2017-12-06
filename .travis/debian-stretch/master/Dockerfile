FROM debian:stretch
COPY envoy /srv/envoy
COPY .travis/entrypoint_master_run.sh /opt/
COPY .travis/config/master.conf /etc/salt/master.d/master.conf
COPY .travis/config/reactor_master.conf /etc/salt/master.d/reactor.conf
COPY .travis/config/supervisord_master.conf /etc/supervisor/conf.d/supervisord.conf
COPY .travis/reactor /srv/reactor
COPY .travis/pillar /srv/pillar

RUN apt-get update && \
    apt-get install -y curl supervisor && \
    ln -s /srv/envoy/salt /srv/salt && \
    ln -s /srv/envoy/extensions /srv/salt_ext && \
    curl -L https://bootstrap.saltstack.com > /tmp/bootstrap.sh && \
    sh /tmp/bootstrap.sh -M -N

ARG SALTENV
ARG LOG_LEVEL
ENV LOG_LEVEL=$LOG_LEVEL
ENV SALTENV=$SALTENV

EXPOSE 4505:4505 4506:4506

ENTRYPOINT ["/opt/entrypoint_master_run.sh"]
