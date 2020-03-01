ARG tag="31"
FROM fedora:$tag AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt

RUN dnf -y --nogpgcheck update && dnf -y --nogpgcheck install curl procps dumb-init && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -x python3 -X -P -n $salt_ver

WORKDIR /srv


FROM salt-base AS salt-minion

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

RUN dnf -y --nogpgcheck install python3-pip git @development-tools redhat-rpm-config python3-devel libgit2-devel && \
    pip3 install --upgrade pathlib pyOpenSSL pygit2==$pip3_pygit2_ver docker-py cherrypy jinja2 PyYAML requests_oauthlib google-auth && \
    dnf -y --nogpgcheck install salt-master

RUN if [ "$API_ENABLED" = true ]; then \
        dnf -y --nogpgcheck install salt-api; \
    fi

RUN if [ "$K8S_API_ENABLED" = true ]; then \
        curl -LO https://storage.googleapis.com/kubernetes-release/release/$kubectl_ver/bin/linux/amd64/kubectl && \
        chmod +x kubectl && \
        mv kubectl /usr/bin/ && \
        pip3 install kubernetes==$pip3_kubernetes_ver && \
        salt-run saltutil.sync_all; \
    fi


# somehow installed pip3 as pip alternative didn't work
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
