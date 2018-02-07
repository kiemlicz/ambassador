FROM debian:sid

# "" == latest
ARG SALT_VER=""
# on debian-sid salt installs under python3 lib path but python2 is the default

COPY envoy /srv/envoy
COPY .travis/envoy_test.py /opt/
COPY .travis/entrypoint_dry.sh /opt/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/pillar /srv/pillar

RUN apt-get update && apt-get install -y curl && \
    ln -s /srv/envoy/salt /srv/salt && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -n stable $SALT_VER

ENTRYPOINT ["/opt/entrypoint_dry.sh"]
