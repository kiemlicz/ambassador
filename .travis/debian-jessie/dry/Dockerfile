FROM debian:jessie

# "" == latest
ARG SALT_VER=""

COPY envoy /srv/envoy
COPY .travis/envoy_test.py /opt/
COPY .travis/entrypoint_dry.sh /opt/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/pillar /srv/pillar

RUN apt-get update && apt-get install -y curl && \
    ln -s /srv/envoy/salt /srv/salt && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh stable $SALT_VER || true
# interesting, in debian:jessie's `ps aux` doesn't list salt-minion although it is running
# this is why `|| true` is mandatory

ENTRYPOINT ["/opt/entrypoint_dry.sh"]
