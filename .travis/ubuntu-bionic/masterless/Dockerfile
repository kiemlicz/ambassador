FROM ubuntu:bionic

ARG log_level
ARG saltenv
ARG pillarenv
ARG salt_ver

COPY envoy /srv/envoy
COPY .travis/entrypoint_masterless_run.sh /opt/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/pillar/$pillarenv /srv/pillar/base/
COPY .travis/salt/top.sls /srv/envoy/salt/base/

RUN apt-get update && apt-get remove -y gnupg iproute2 && \
    apt-get install -y --reinstall gnupg2 && \
    apt-get install -y curl dirmngr python-pip && \
    ln -s /srv/envoy/salt /srv/salt && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -n -d -X $salt_ver && \
    ln -sf /dev/stdout /var/log/salt/minion

ENV SALTENV=$saltenv
ENV LOG_LEVEL=$log_level

ENTRYPOINT /opt/entrypoint_masterless_run.sh $SALTENV $LOG_LEVEL
