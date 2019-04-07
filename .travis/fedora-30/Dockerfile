FROM fedora:30 AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt

RUN dnf -y --nogpgcheck update && dnf -y --nogpgcheck install curl procps && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -x python3 -X -n stable $salt_ver


FROM salt-base AS salt-minion

ENTRYPOINT [ "/usr/bin/salt-minion" ]
CMD []


FROM salt-base AS salt-master

RUN dnf -y --nogpgcheck install python3-pip git @development-tools redhat-rpm-config python3-devel libgit2-devel && \
    alternatives --install /usr/bin/pip pip /usr/bin/pip3 20 && \
    pip3 install --upgrade pyOpenSSL pygit2 docker-py cherrypy jinja2 PyYAML requests_oauthlib google-auth && \
    dnf -y --nogpgcheck install salt-master

# somehow installed pip3 as pip alternative didn't work
# the salt-master should be installed but not running
EXPOSE 4505:4505 4506:4506

ENTRYPOINT [ "/usr/bin/salt-master" ]
CMD []


FROM salt-base AS dry-test

COPY .travis/reactor /srv/reactor
COPY .travis/pillar/dry-test/ /srv/pillar/
COPY .travis/salt/dry-test-top.sls /srv/salt/base/top.sls
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/config/pillar.conf /etc/salt/minion.d/pillar.conf
COPY .travis/envoy_test.py /opt/

RUN salt-call --local saltutil.sync_all

#don't understand why not python3
ENTRYPOINT [ "python", "/opt/envoy_test.py" ]
