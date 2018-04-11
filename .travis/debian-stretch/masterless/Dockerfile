FROM debian:stretch

ARG LOG_LEVEL
ARG SALTENV
ARG PILLARENV
# "" == latest
ARG SALT_VER=""

COPY envoy /srv/envoy
COPY .travis/entrypoint_masterless_run.sh /opt/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/pillar /srv/pillar
COPY .travis/infra /opt/infra
COPY .travis/debian-stretch/infra /opt/infra

RUN apt-get update && apt-get install -y curl python-pip && \
    ln -s /srv/envoy/salt /srv/salt && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -n stable $SALT_VER && \
    ln -sf /dev/stdout /var/log/salt/minion && \
    pip install --upgrade && pip install --upgrade testinfra

ENV SALTENV=$SALTENV
ENV PILLARENV=$PILLARENV
ENV LOG_LEVEL=$LOG_LEVEL

ENTRYPOINT /opt/entrypoint_masterless_run.sh $SALTENV $PILLARENV $LOG_LEVEL
