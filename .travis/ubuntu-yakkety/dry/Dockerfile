FROM ubuntu:yakkety

# "" == latest
ARG SALT_VER=""

COPY envoy /srv/envoy
COPY .travis/envoy_test.py /opt/
COPY .travis/entrypoint_dry.sh /opt/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/pillar /srv/pillar

RUN apt-get update && apt-get remove -y gnupg && \
    apt-get install -y --reinstall gnupg2 && \
    apt-get install -y curl dirmngr && \
    ln -s /srv/envoy/salt /srv/salt && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh stable $SALT_VER

ENTRYPOINT ["/opt/entrypoint_dry.sh"]
