FROM kiemlicz/envoy-minion-ubuntu-bionic AS test-base-minion
FROM kiemlicz/envoy-master-ubuntu-bionic AS test-base-master


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


FROM test-base-minion as minion-compose-test

COPY .travis/config/minion.conf /etc/salt/minion.d/minion.conf
