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
# hostname from `docker run -h` must be used as minion ID

RUN dnf -y --nogpgcheck install python3-pip && \
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

RUN dnf -y --nogpgcheck install python3-pip git @development-tools redhat-rpm-config python3-devel libgit2-devel && \
    pip3 install --upgrade pathlib pyOpenSSL pygit2==$pip3_pygit2_ver docker-py cherrypy jinja2 PyYAML && \
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

VOLUME /etc/salt/pki/master
VOLUME /var/cache/salt/master/queues
VOLUME /etc/pki/tls/certs
VOLUME /etc/salt/cloud.providers.d
VOLUME /srv/thorium
VOLUME /srv/pillar
VOLUME /etc/salt/master.d

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "/opt/entrypoint.sh" ]


FROM salt-base AS salt-test

ARG log_level="INFO"
ARG saltenv
ENV SALTENV=$saltenv
ENV LOG_LEVEL=$log_level

RUN dnf -y --nogpgcheck install -y python3-pip && pip3 install --upgrade pytest pytest-xdist redis

COPY .travis/top.sls /srv/salt/base/top.sls
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/conftest.py .travis/test-runner-pytest.py .travis/pytest.ini .travis/test_pillar.py /opt/

WORKDIR /opt

ENTRYPOINT [ "pytest", "test-runner-pytest.py" ]
CMD ["--log-level", "INFO" ]
