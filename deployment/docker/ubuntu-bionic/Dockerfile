ARG tag="bionic"
FROM ubuntu:$tag AS salt-base
# "" == latest
ARG salt_ver=""
ARG pip3_ver="20.3.3"
ARG master_user="root"
ARG minion_user="root"
ENV DEBIAN_FRONTEND noninteractive
ENV PIP3_VER=$pip3_ver

# using pip-based salt installation, otherwise pip-installing (during state execution) may fail
# reload doesn't reload dependencies and possibly old apt-based python packages are still used
# e.g. gdrive needs new cryptodome, old is present due to salt bootstrap script, "incomplete" reload fails further executions
RUN useradd -ms /bin/bash salt && \
    apt-get update && apt-get install -y curl dirmngr procps iproute2 dumb-init python3-pip python3-apt && \
    pip3 install pip=="$PIP3_VER" && \
    mkdir -p /var/cache/salt /var/log/salt && \
    curl -o /opt/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /opt/bootstrap-salt.sh -x python3 -X -P -n $salt_ver && \
    chown -R salt.salt /etc/salt /var/cache/salt /var/log/salt

COPY --chown=salt:salt salt /srv/salt

WORKDIR /srv


FROM salt-base AS salt-minion
# hostname from `docker run -h` must be used as minion ID

RUN pip3 install --upgrade docker

VOLUME /etc/salt/minion.d

USER $minion_user:$minion_user
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

RUN pip3 install --upgrade pyOpenSSL pygit2==$pip3_pygit2_ver docker jinja2 requests

RUN if [ "$API_ENABLED" = true ]; then \
        pip3 install --upgrade cherrypy; \
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

USER $master_user:$master_user
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "/opt/entrypoint.sh" ]


FROM salt-base AS salt-test

ARG log_level="INFO"
ARG saltenv
ENV SALTENV=$saltenv
ENV LOG_LEVEL=$log_level

# installing setuptools before tests since google-auth requires > 40.3 and bionic python3-setuptools is 39
# pip3 installing setuptools during test run (with module reload and apt-get purge of python3-setuptools) doesn't help (in the one run)
RUN apt-get install -y python3-pip && pip3 install --upgrade pytest pytest-xdist redis setuptools

# workaround for salt's service state
# somehow in masterless config the service provider cannot be overriden
# https://github.com/saltstack/salt/issues/33256
RUN printf '#!/bin/bash\necho "N 5"' > /sbin/runlevel && \
    chmod 775 /sbin/runlevel

COPY .travis/top.sls /srv/salt/base/top.sls
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/conftest.py .travis/test-runner-pytest.py .travis/pytest.ini .travis/test_pillar.py /opt/

WORKDIR /opt

# tests are extensive, root required
USER root:root
ENTRYPOINT [ "pytest", "test-runner-pytest.py" ]
CMD ["--log-level", "INFO" ]
