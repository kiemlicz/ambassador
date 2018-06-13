#!/usr/bin/env bash

set -e
if [ -z "$DOCKER_IMAGE" ]; then
    >&2 echo "Docker image must be provided" #stderror print
    exit 1
fi

COMPOSE_VER="1.19.0"

docker_compose_update() {
    local docker_compose_version=$COMPOSE_VER

    docker-compose --version
    sudo rm /usr/local/bin/docker-compose
    curl -L https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m` > docker-compose
    chmod +x docker-compose
    sudo mv docker-compose /usr/local/bin
    docker-compose --version
    docker --version
}

docker_update() {
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce
}


case "$TEST_CASE" in
salt-masterless-run)
    docker_update
    docker build --build-arg=SALT_VER=$SALT_VER --build-arg=LOG_LEVEL="${LOG_LEVEL-info}" --build-arg=SALTENV="$SALTENV" --build-arg=PILLARENV="$PILLARENV" -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/masterless/Dockerfile .
    ;;
salt-master-run)
    docker_update
    docker_compose_update
    docker-compose -f .travis/docker-compose.yml --project-directory=. --no-ansi up --no-start
    ;;
ambassador-run)
    #docker build --build-arg=FQDN="$TEST_FQDN" -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/run/Dockerfile .
    sudo mkdir -p /etc/foreman/ssl/private/
    sudo mkdir -p /etc/foreman/ssl/certs/
    sudo mkdir -p /etc/foreman/ssl/
    sudo mkdir -p /etc/salt/
    sudo mkdir -p /var/tmp/
    sudo mkdir -p /etc/dnsmasq.d/
    sudo mkdir -p /etc/foreman-proxy/settings.d/
    sudo mkdir -p /etc/systemd/system/
    sudo mkdir -p /opt/file_ext_authorize/

    cp .travis/config/ssl/*.key /etc/foreman/ssl/private/
    cp .travis/config/ssl/*.cert /etc/foreman/ssl/certs/
    cp .travis/config/ssl/crl.pem /etc/foreman/ssl/
    cp .travis/config/foreman.yaml /etc/salt/
    cp .travis/config/30-saltfs.conf /var/tmp/
    cp .travis/config/proxydhcp.conf /etc/dnsmasq.d/
    cp .travis/config/salt.yml /etc/foreman-proxy/settings.d/
    cp config/file_ext_authorize.service /etc/systemd/system/
    cp .travis/config/file_ext_authorize.conf /opt/file_ext_authorize/
    cp extensions/file_ext_authorize/* /opt/file_ext_authorize/
    cp run.sh /opt/

    apt-get clean && apt-get update && apt-get install -y locales && \
        sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

    export CID=$FQDN
    export CIP="192.168.1.7"
    export CRL="/etc/foreman/ssl/crl.pem"
    export CA="/etc/foreman/ssl/certs/ca.cert"
    export CERT="/etc/foreman/ssl/certs/server.cert"
    export PROXY_CERT="/etc/foreman/ssl/certs/server.cert"
    export KEY="/etc/foreman/ssl/private/server.key"
    export PROXY_KEY="/etc/foreman/ssl/private/server.key"
    export CERT_BASEDIR="/etc/foreman/ssl/"
    export LANG=en_US.UTF-8
    export LANGUAGE=en_US:en
    export LC_ALL=en_US.UTF-8
    ;;
esac
