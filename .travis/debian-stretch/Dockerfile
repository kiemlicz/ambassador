FROM kiemlicz/envoy-minion-debian-stretch AS test-base-minion
FROM kiemlicz/envoy-master-debian-stretch AS test-base-master


FROM test-base-master AS master-compose-test

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
COPY envoy/salt/base/_log_handlers/logstash_mod.py /usr/lib/python3/dist-packages/salt/log/handlers/

RUN chmod 600 /etc/salt/autosign.conf && \
    salt-run saltutil.sync_all

ENTRYPOINT [ "/opt/entrypoint_master_run.sh" ]


FROM test-base-master AS master-k8s-test

ARG saltenv
ARG log_level
ARG kubectl_ver

ENV SALTENV=$saltenv
ENV LOG_LEVEL=$log_level

COPY .travis/entrypoint_master_run.sh /opt/
COPY .travis/scan_events.py /opt/
COPY .travis/config/master.conf /etc/salt/master.d/master.conf
COPY .travis/config/autosign.conf /etc/salt/autosign.conf
COPY .travis/config/reactor_k8s.conf /etc/salt/master.d/reactor.conf
COPY .travis/config/reactor/k8s /srv/reactor
COPY .travis/pillar/ /srv/pillar/
COPY .travis/salt/ /srv/salt/
# sync via _log_handlers does nothing... forcing override of installed packages
COPY envoy/salt/base/_log_handlers/logstash_mod.py /usr/lib/python3/dist-packages/salt/log/handlers/

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$kubectl_ver/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/bin/ && \
    chmod 600 /etc/salt/autosign.conf && \
    salt-run saltutil.sync_all

ENTRYPOINT [ "/opt/entrypoint_master_run.sh" ]


FROM test-base-minion AS masterless-test

ARG log_level="info"
ARG saltenv

ENV SALTENV=$saltenv
ENV LOG_LEVEL=$log_level

COPY .travis/pillar/ /srv/pillar/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/salt/top.sls /srv/salt/base/

# workaround for salt's service state
# somehow in masterless config the service provider cannot be overriden
# https://github.com/saltstack/salt/issues/33256
RUN printf '#!/bin/bash\necho "N 5"' > /sbin/runlevel && \
    chmod 775 /sbin/runlevel

ENTRYPOINT salt-call --local state.highstate saltenv=$SALTENV -l $LOG_LEVEL


FROM test-base-minion as minion-compose-test

COPY .travis/config/minion.conf /etc/salt/minion.d/minion.conf


FROM test-base-minion as minion-k8s-test

COPY .travis/config/minion.conf /etc/salt/minion.d/minion.conf
COPY envoy/salt/base/_log_handlers/logstash_mod.py /usr/lib/python3/dist-packages/salt/log/handlers/

RUN apt-get install -y python3-pip && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 20 && \
    pip install docker redis
