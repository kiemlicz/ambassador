FROM ubuntu:xenial
RUN apt-get update && apt-get install -y curl
RUN curl -L https://bootstrap.saltstack.com | sh || true
COPY envoy /srv/envoy
COPY .travis/envoy_test.py /opt/
COPY .travis/minion.conf /etc/salt/minion
COPY .travis/pillar /srv
RUN ln -s /srv/envoy/salt /srv/salt && service salt-minion restart

ENTRYPOINT ["python", "/opt/envoy_test.py"]
