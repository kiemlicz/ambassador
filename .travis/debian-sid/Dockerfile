FROM kiemlicz/envoy-minion-debian-sid AS test-base-minion


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
RUN echo -e '#!/bin/bash\necho "N 5"' > /sbin/runlevel && \
    chmod 775 /sbin/runlevel

ENTRYPOINT salt-call --local state.highstate saltenv=$SALTENV -l $LOG_LEVEL
