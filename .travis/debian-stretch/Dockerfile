ARG tag="stretch-slim"
FROM debian:$tag AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt

RUN apt-get update && apt-get install -y procps curl dumb-init && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -x python3 -X -n $salt_ver

# sync via _log_handlers does nothing... forcing override of installed packages
# temporary workaound until PR with this fix is merged&released
COPY salt/base/_log_handlers/logstash_mod.py /usr/lib/python3/dist-packages/salt/log/handlers/

WORKDIR /srv


FROM salt-base AS salt-minion
# hostname from `docker run -h` must be used as minion ID

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "/usr/bin/salt-minion" ]


FROM salt-base AS salt-master

ARG api_enabled=false
ARG k8s_api_enabled=false
ENV API_ENABLED=$api_enabled
ENV K8S_API_ENABLED=$k8s_api_enabled

RUN echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list.d/backports.list && \
    apt-get update && \
    apt-get install -t stretch-backports -y libgit2-dev && \
    apt-get install -y python3-pip libffi-dev git && \
    pip3 install --upgrade pyOpenSSL pygit2 docker-py cherrypy jinja2 requests_oauthlib google-auth && \
    apt-get install -y salt-master

RUN if [ "$API_ENABLED" = true ]; then \
        apt-get install -y salt-api; \
    fi

RUN if [ "$K8S_API_ENABLED" = true ]; then \
        curl -LO https://storage.googleapis.com/kubernetes-release/release/$kubectl_ver/bin/linux/amd64/kubectl && \
        chmod +x kubectl && \
        mv kubectl /usr/bin/ && \
        pip3 install --upgrade kubernetes && \
        salt-run saltutil.sync_all; \
    fi

# PyYAML
#pip install --upgrade --default-timeout=300 pip && hash -r pip && \
# the salt-master should be installed but not running
EXPOSE 4505:4505 4506:4506

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "/usr/bin/salt-master" ]


FROM salt-master AS salt-master-foreman-proxy

COPY .travis/debian-stretch/entrypoint.sh /opt/

RUN echo "deb http://deb.theforeman.org/ stretch 1.23" >> /etc/apt/sources.list.d/foreman.list && \
    wget -q https://deb.theforeman.org/pubkey.gpg -O- | apt-key add - && \
    apt-get update && \
    apt-get install -y foreman-proxy

CMD [ "/opt/entrypoint.sh" ]


FROM salt-base AS dry-test

#todo this reactor doesn't seem to be necessary
#COPY .travis/reactor /srv/reactor
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

RUN chmod 600 /etc/salt/autosign.conf && \
    salt-run saltutil.sync_all

CMD [ "/opt/entrypoint_master_run.sh" ]


FROM salt-master AS master-k8s-test

ARG saltenv
ARG kubectl_ver

ENV SALTENV=$saltenv

# todo scan differently and remove scan_events with its weird entrypoint
COPY .travis/entrypoint_master_run.sh /opt/
COPY .travis/scan_events.py /opt/

CMD [ "/opt/entrypoint_master_run.sh" ]


FROM salt-minion as minion-compose-test

COPY .travis/config/minion.conf /etc/salt/minion.d/minion.conf


FROM salt-minion as minion-k8s-test

COPY .travis/config/minion.conf /etc/salt/minion.d/minion.conf

RUN apt-get install -y python3-pip && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 20 && \
    pip install docker redis
