FROM debian:sid
RUN apt-get update && apt-get install -y curl
COPY envoy /srv/envoy
COPY .travis/envoy_test.py /opt/
COPY .travis/debian-sid/assertions.py /opt/
COPY .travis/entrypoint_dry.sh /opt/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/pillar /srv/pillar
RUN ln -s /srv/envoy/salt /srv/salt
RUN curl -L https://bootstrap.saltstack.com | sh

ENTRYPOINT ["/opt/entrypoint_dry.sh"]
