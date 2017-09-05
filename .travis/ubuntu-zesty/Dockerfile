FROM ubuntu:zesty
RUN apt-get update && apt-get remove -y gnupg && apt-get install -y --reinstall gnupg2 && apt-get install -y curl dirmngr
COPY envoy /srv/envoy
COPY .travis/envoy_test.py /opt/
COPY .travis/entrypoint_dry.sh /opt/
COPY .travis/minion.conf /etc/salt/minion.d/minion.conf
COPY .travis/pillar /srv/pillar
RUN ln -s /srv/envoy/salt /srv/salt
RUN curl -L https://bootstrap.saltstack.com/develop | sh || true

ENTRYPOINT ["/opt/entrypoint_dry.sh"]
