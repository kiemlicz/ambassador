ARG tag="31"
FROM fedora:$tag AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt

RUN dnf -y --nogpgcheck update && dnf -y --nogpgcheck install curl procps dumb-init && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -x python3 -X -n $salt_ver

WORKDIR /srv


FROM salt-base AS salt-minion

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "/usr/bin/salt-minion" ]


FROM salt-base AS salt-master

RUN dnf -y --nogpgcheck install python3-pip git @development-tools redhat-rpm-config python3-devel libgit2-devel && \
    alternatives --install /usr/bin/pip pip /usr/bin/pip3 20 && \
    pip3 install --upgrade pathlib pyOpenSSL pygit2 docker-py cherrypy jinja2 PyYAML requests_oauthlib google-auth && \
    dnf -y --nogpgcheck install salt-master

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

#don't understand why not python3
ENTRYPOINT [ "python", "/opt/envoy_test.py" ]
CMD []
