#!/usr/bin/env bash

set -e
if [ -z "$DOCKER_IMAGE" ]; then
    >&2 echo "Docker image must be provided" #stderror print
    exit 1
fi

source envoy/.travis/common.sh

docker_build() {
    if [ -z $1 ]; then
        >&2 echo "Dockerfile target missing"
        exit 4
    fi
    docker build \
        --build-arg=salt_ver=$SALT_VER \
        --build-arg=log_level="${LOG_LEVEL-info}" \
        --build-arg=saltenv="$SALTENV" \
        --build-arg=context="$CONTEXT" \
        --build-arg=kubectl_ver="$KUBECTL_VER" \
        -t "${2-$DOCKER_IMAGE}" \
        --target $1 \
        -f .travis/"$DOCKER_IMAGE"/Dockerfile .
}

case "$TEST_CASE" in
salt-masterless-run)
    docker_update
    docker_build masterless-test
    ;;
salt-master-run-compose)
    docker_update
    docker_compose_update
    docker-compose -f .travis/docker-compose.yml --project-directory=. up --no-start
    ;;
salt-master-run-k8s)
    # todo update to specific docker-ce version apt-get install docker-ce=18.06.1~ce~3-0~debian
    kubectl_install
    minikube_install
    #create PV paths manually
    sudo mkdir -p /mnt/data/r0 /mnt/data/r1 /mnt/data/r2 /mnt/data/r3 /mnt/data/r4 /mnt/data/r5 /mnt/data/r6
    # build images that are used for provisioning (salt master's and minion's)
    # only one of each is required per one node cluster
    docker_build master-k8s-test salt_master
    docker_build minion-k8s-test salt_minion
    ;;
esac
