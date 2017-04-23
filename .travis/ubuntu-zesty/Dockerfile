FROM ubuntu:zesty
RUN apt-get update && apt-get remove -y gnupg && apt-get install -y --reinstall gnupg2 && apt-get install -y curl dirmngr
RUN curl -L https://bootstrap.saltstack.com | sh
COPY envoy /srv/envoy
COPY .travis/envoy_test.py /opt/
COPY .travis/minion.conf /etc/salt/minion
COPY .travis/pillar /srv/pillar
RUN ln -s /srv/envoy/salt /srv/salt && service salt-minion restart

ENTRYPOINT ["python", "/opt/envoy_test.py"]
