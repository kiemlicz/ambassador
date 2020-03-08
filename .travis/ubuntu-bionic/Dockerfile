ARG tag="bionic"
FROM ubuntu:$tag AS salt-base
# "" == latest
ARG salt_ver=""

ENV DEBIAN_FRONTEND noninteractive

COPY salt /srv/salt

RUN apt-get update && apt-get install -y curl procps dirmngr iproute2 dumb-init && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -x python3 -X -n $salt_ver

WORKDIR /srv


FROM salt-base AS salt-minion
# hostname from `docker run -h` must be used as minion ID

RUN apt-get install -y python3-pip && \
    pip3 install --upgrade docker

VOLUME /etc/salt/minion.d

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "/usr/bin/salt-minion" ]


FROM salt-base AS salt-master

ARG api_enabled=false
ARG k8s_api_enabled=false
ARG kubectl_ver
ARG pip3_kubernetes_ver
ARG pip3_pygit2_ver
ARG saltenv
ENV API_ENABLED=$api_enabled
ENV K8S_API_ENABLED=$k8s_api_enabled
ENV SALTENV=$saltenv

# minimalistic config
COPY .travis/config/master.conf /etc/salt/master.d/01-master.conf
COPY .travis/entrypoint.sh /opt/

RUN apt-get update && \
    apt-get install -y python3-pip libffi-dev libgit2-dev git && \
    pip3 install --upgrade pyOpenSSL pygit2==$pip3_pygit2_ver docker-py cherrypy jinja2 requests_oauthlib google-auth requests && \
    apt-get install -y salt-master

RUN if [ "$API_ENABLED" = true ]; then \
        apt-get install -y salt-api; \
    fi

RUN if [ "$K8S_API_ENABLED" = true ]; then \
        curl -LO https://storage.googleapis.com/kubernetes-release/release/$kubectl_ver/bin/linux/amd64/kubectl && \
        chmod +x kubectl && \
        mv kubectl /usr/bin/ && \
        pip3 install kubernetes==$pip3_kubernetes_ver && \
        salt-run saltutil.sync_all; \
    fi

EXPOSE 4505:4505 4506:4506

VOLUME /etc/salt/pki/master
VOLUME /var/cache/salt/master/queues
VOLUME /etc/pki/tls/certs
VOLUME /etc/salt/cloud.providers.d
VOLUME /srv/thorium
VOLUME /srv/pillar
VOLUME /etc/salt/master.d

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "/opt/entrypoint.sh" ]


FROM salt-base AS dry-test

#COPY .travis/reactor /srv/reactor
COPY .travis/salt/dry-test-top.sls /srv/salt/base/top.sls
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/test-runner.py /opt/

WORKDIR /opt

RUN salt-call --local saltutil.sync_all

ENTRYPOINT [ "python3", "/opt/test-runner.py" ]
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
