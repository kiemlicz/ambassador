FROM kiemlicz/envoy-minion-debian-stretch AS test-base-minion
FROM kiemlicz/envoy-master-debian-stretch AS test-base-master


FROM test-base-master AS master-compose-test

ARG saltenv
ARG log_level

COPY .travis/entrypoint_master_run.sh /opt/
COPY .travis/scan_events.py /opt/
COPY .travis/tests /opt/tests
COPY .travis/config/master.conf /etc/salt/master.d/master.conf
COPY .travis/config/autosign.conf /etc/salt/autosign.conf
COPY .travis/config/reactor_orch.conf /etc/salt/master.d/reactor.conf
COPY .travis/config/reactor/orch /srv/reactor
COPY .travis/pillar/ /srv/pillar/
COPY .travis/salt/dev/top.sls /srv/salt/base/
COPY .travis/salt/dev/_orchestrate /srv/salt/dev/_orchestrate

RUN chmod 600 /etc/salt/autosign.conf

ENV SALTENV=$saltenv
ENV LOG_LEVEL=$log_level
ENTRYPOINT [ "/opt/entrypoint_master_run.sh" ]


FROM test-base-master AS master-k8s-test

ARG saltenv
ARG log_level
ARG kubectl_ver

COPY .travis/entrypoint_master_run.sh /opt/
COPY .travis/scan_events.py /opt/
COPY .travis/tests /opt/tests
COPY .travis/config/master.conf /etc/salt/master.d/master.conf
COPY .travis/config/autosign.conf /etc/salt/autosign.conf
COPY .travis/config/reactor_k8s.conf /etc/salt/master.d/reactor.conf
COPY .travis/config/reactor/k8s /srv/reactor
COPY .travis/pillar/ /srv/pillar/
COPY .travis/salt/dev/top.sls /srv/salt/base/
COPY .travis/salt/dev/_orchestrate /srv/salt/dev/_orchestrate
COPY .travis/k8s /opt/k8s

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$kubectl_ver/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/bin/ && \
    chmod 600 /etc/salt/autosign.conf

VOLUME /etc/kubernetes

ENV SALTENV=$saltenv
ENV LOG_LEVEL=$log_level
ENTRYPOINT [ "/opt/entrypoint_master_run.sh" ]


FROM test-base-minion AS masterless-test

ARG log_level
ARG saltenv

COPY .travis/pillar/ /srv/pillar/
COPY .travis/entrypoint_masterless_run.sh /opt/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/salt/top.sls /srv/salt/base/

ENV SALTENV=$saltenv
ENV LOG_LEVEL=$log_level

ENTRYPOINT /opt/entrypoint_masterless_run.sh $SALTENV $LOG_LEVEL


FROM test-base-minion as minion-compose-test

COPY .travis/config/minion.conf /etc/salt/minion.d/minion.conf


FROM test-base-minion as minion-k8s-test

COPY .travis/config/minion.conf /etc/salt/minion.d/minion.conf

RUN apt-get update && \
    apt-get install -y python-pip && \
    pip install docker redis
