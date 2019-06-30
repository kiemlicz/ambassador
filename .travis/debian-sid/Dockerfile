FROM debian:sid-slim AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt

RUN apt-get update && apt-get install -y curl dumb-init && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -x python3 -X -n stable $salt_ver

WORKDIR /srv


FROM salt-base AS salt-minion

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "/usr/bin/salt-minion" ]


FROM salt-base AS salt-master

RUN apt-get install -y libgit2-dev python3-pip libffi-dev git && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 20 && \
    pip install --upgrade pyOpenSSL pygit2 docker-py cherrypy jinja2 PyYAML requests_oauthlib google-auth && \
    apt-get install -y salt-master

# the salt-master should be installed but not running
EXPOSE 4505:4505 4506:4506

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "/usr/bin/salt-master" ]


FROM salt-base AS dry-test

COPY .travis/reactor /srv/reactor
COPY .travis/salt/dry-test-top.sls /srv/salt/base/top.sls
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/envoy_test.py /opt/

WORKDIR /opt

RUN salt-call --local saltutil.sync_all

ENTRYPOINT [ "python3", "/opt/envoy_test.py" ]
CMD []


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

CMD salt-call --local state.highstate saltenv=$SALTENV -l $LOG_LEVEL
