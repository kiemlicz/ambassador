ARG tag="buster-slim"
FROM debian:$tag AS salt-base
# "" == latest
ARG salt_ver=""
ARG master_user="root"
ARG minion_user="root"

COPY config/requirements.txt /tmp
# fixme install using install script
# receiving a lot of issues when not upgrading `six` and `pip` prior to salt run...
RUN useradd -ms /bin/bash salt && \
    apt-get update && apt-get install -y curl procps dumb-init python3-pip python3-apt rustc libssl-dev && \
    pip3 install -r /tmp/requirements.txt && \
    mkdir -p /var/cache/salt /var/log/salt && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltproject.io && \
    sh /tmp/bootstrap-salt.sh -x python3 -X -n $salt_ver &&\
    chown -R salt.salt /etc/salt /var/cache/salt /var/log/salt

COPY --chown=salt:salt salt /srv/salt
RUN rm -rf /tmp/bootstrap-salt.sh && rm -rf /tmp/requirements.txt

WORKDIR /srv


FROM salt-base AS salt-minion
# hostname from `docker run -h` must be used as minion ID
# todo confirm not needed
#RUN pip3 install --upgrade docker

VOLUME /etc/salt/minion.d

USER $minion_user:$minion_user
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "/usr/local/bin/salt-minion" ]


FROM salt-base AS salt-master

ARG api_enabled=false
ARG k8s_api_enabled=false
ARG kubectl_ver
ARG saltenv
ENV API_ENABLED=$api_enabled
ENV K8S_API_ENABLED=$k8s_api_enabled
ENV SALTENV=$saltenv

# minimalistic config
COPY .travis/config/master.conf /etc/salt/master.d/01-master.conf
COPY .travis/entrypoint.sh /opt/

RUN if [ "$API_ENABLED" = true ]; then \
        pip3 install --upgrade pyOpenSSL cherrypy; \
    fi

RUN if [ "$K8S_API_ENABLED" = true ]; then \
        curl -LO https://storage.googleapis.com/kubernetes-release/release/$kubectl_ver/bin/linux/amd64/kubectl && \
        chmod +x kubectl && \
        mv kubectl /usr/bin/ && \
        pip3 install kubernetes~=10.0.1 && \
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

RUN pip3 install --upgrade pytest pytest-xdist redis

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
