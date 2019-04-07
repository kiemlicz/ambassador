FROM ubuntu:xenial AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt

RUN apt-get update && apt-get install -y curl iproute2 && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -x python3 -X -n stable $salt_ver


FROM salt-base AS salt-minion

ENTRYPOINT [ "/usr/bin/salt-minion" ]
CMD []


FROM salt-base AS salt-master

RUN apt-get install -y python3-pip && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 20 && \
    curl -L https://gist.githubusercontent.com/kiemlicz/33e891dd78e985bd080b85afa24f5d0a/raw/1f5ce21454c10283d0c7d3f15a15ff46ad324fdb/init.sh && \
    apt-get install -y salt-master

# the salt-master should be installed but not running
EXPOSE 4505:4505 4506:4506

ENTRYPOINT [ "/usr/bin/salt-master" ]
CMD []


FROM salt-base AS dry-test

COPY .travis/reactor /srv/reactor
COPY .travis/pillar/dry-test /srv/pillar/
COPY .travis/salt/dry-test-top.sls /srv/salt/base/top.sls
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/config/pillar.conf /etc/salt/minion.d/pillar.conf
COPY .travis/envoy_test.py /opt/

RUN salt-call --local saltutil.sync_all

ENTRYPOINT [ "python3", "/opt/envoy_test.py" ]
