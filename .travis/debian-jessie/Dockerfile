FROM debian:jessie
RUN apt-get update && apt-get install -y curl dbus
RUN curl -L https://bootstrap.saltstack.com | sh || true
COPY envoy /srv/envoy
COPY .travis/envoy_test.py /opt/
COPY .travis/minion.conf /etc/salt/minion
RUN ln -s /srv/envoy/salt /srv/salt && ln -s /srv/envoy/pillar /srv/pillar && service salt-minion restart

ENTRYPOINT ["python", "/opt/envoy_test.py"]
