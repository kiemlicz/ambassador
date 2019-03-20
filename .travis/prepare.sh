#!/usr/bin/env bash

set -e
if [ -z "$DOCKER_IMAGE" ]; then
    >&2 echo "Docker image must be provided" #stderror print
    exit 1
fi

source envoy/.travis/common.sh
KUBECTL_VER="v1.13.4"

docker_build() {
    if [ -z $1 ]; then
        >&2 echo "Dockerfile target missing"
        exit 4
    fi
    docker build \
        --build-arg=salt_ver=$SALT_VER \
        --build-arg=log_level="${LOG_LEVEL-info}" \
        --build-arg=saltenv="$SALTENV" \
        --build-arg=kubectl_ver="$KUBECTL_VER" \
        --target $1 \
        -t "${2-$DOCKER_IMAGE}" \
        -f .travis/"$DOCKER_IMAGE"/Dockerfile .
}

salt_install() {
    sudo apt-get update && sudo apt-get install -y curl
    sudo mkdir -p /etc/salt/minion.d/
    sudo cp ${1-".travis/config/masterless.conf"} /etc/salt/minion.d/
    sudo ln -s $TRAVIS_BUILD_DIR/envoy/salt /srv/salt
    sudo ln -s $TRAVIS_BUILD_DIR/.travis/pillar /srv/pillar
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com
    sudo sh /tmp/bootstrap-salt.sh -x python3 -n stable
}

minikube_ready() {
    echo "Waiting for nodes..."
    kubectl get nodes
    kubectl wait nodes/minikube --for condition=ready
    echo "minikube setup complete"
}

minikube_install() {
    sudo salt-call --local state.apply kubernetes.client saltenv=server
    sudo salt-call --local state.apply kubernetes.minikube saltenv=server
    sudo salt-call --local state.apply kubernetes.helm saltenv=server
    minikube_ready
}

case "$TEST_CASE" in
salt-master-run-compose)
    docker_update
    docker_compose_update
    docker-compose -f .travis/docker-compose.yml --project-directory=. up --no-start
    ;;
salt-master-run-k8s)
    salt_install
    sudo salt-call --local saltutil.sync_all
    echo "ID: $(salt-call --local grains.get id)"
    minikube_install
    echo "hostname: $(hostname)"
    #create PV paths manually
    sudo mkdir -p /mnt/data/saltpki /mnt/data/saltqueue
    # build images that are used for provisioning (salt master's and minion's)
    # only one of each is required per one node cluster
    docker_build master-k8s-test salt-master
    docker_build minion-k8s-test salt-minion
    ;;
esac
