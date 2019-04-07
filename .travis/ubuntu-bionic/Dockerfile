FROM ubuntu:bionic AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt

RUN apt-get update && apt-get install -y curl dirmngr iproute2 && \
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
COPY .travis/pillar/dry-test/ /srv/pillar/
COPY .travis/salt/dry-test-top.sls /srv/salt/base/top.sls
COPY .travis/config/pillar.conf /etc/salt/minion.d/pillar.conf
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/envoy_test.py /opt/

RUN salt-call --local saltutil.sync_all

ENTRYPOINT [ "python3", "/opt/envoy_test.py" ]


FROM salt-base AS masterless-test

ARG log_level="info"
ARG saltenv

ENV SALTENV=$saltenv
ENV LOG_LEVEL=$log_level

COPY .travis/pillar/masterless/ /srv/pillar/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/salt/masterless-test-top.sls /srv/salt/base/top.sls

# workaround for salt's service state
# somehow in masterless config the service provider cannot be overriden
# https://github.com/saltstack/salt/issues/33256
RUN printf '#!/bin/bash\necho "N 5"' > /sbin/runlevel && \
    chmod 775 /sbin/runlevel

ENTRYPOINT salt-call --local state.highstate saltenv=$SALTENV -l $LOG_LEVEL


FROM salt-master AS master-compose-test

ARG saltenv
ARG log_level

ENV SALTENV=$saltenv
ENV LOG_LEVEL=$log_level

COPY .travis/entrypoint_master_run.sh /opt/
COPY .travis/scan_events.py /opt/
COPY .travis/config/master.conf /etc/salt/master.d/master.conf
COPY .travis/config/autosign.conf /etc/salt/autosign.conf
COPY .travis/config/reactor_orch.conf /etc/salt/master.d/reactor.conf
COPY .travis/config/reactor/orch /srv/reactor
COPY .travis/pillar/ /srv/pillar/
COPY .travis/salt/ /srv/salt/
COPY .travis/salt/dev/top.sls /srv/salt/base/
COPY salt/base/_log_handlers/logstash_mod.py /usr/lib/python3/dist-packages/salt/log/handlers/

RUN chmod 600 /etc/salt/autosign.conf && \
    salt-run saltutil.sync_all

ENTRYPOINT [ "/opt/entrypoint_master_run.sh" ]


FROM salt-minion as minion-compose-test

COPY .travis/config/minion.conf /etc/salt/minion.d/minion.conf
