FROM kiemlicz/envoy-minion-debian-sid AS test-base-minion


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
