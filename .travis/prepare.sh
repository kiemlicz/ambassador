#!/usr/bin/env bash

set -e
if [ -z "$DOCKER_IMAGE" ]; then
    >&2 echo "Docker image must be provided" #stderror print
    exit 1
fi

source .travis/common.sh

case "$1" in
dry)
    if [ "$TRAVIS" = "true" ]; then
        docker_update
    fi
    docker_build salt-minion "envoy-minion-$DOCKER_IMAGE:$TAG"
    docker_build salt-master "envoy-master-$DOCKER_IMAGE:$TAG"
    docker_build dry-test "envoy-dry-test-$DOCKER_IMAGE:$TAG"
    ;;
masterless)
    if [ "$TRAVIS" = "true" ]; then
        docker_update
    fi
    docker_build masterless-test "masterless-test-$DOCKER_IMAGE:$TAG"
    ;;
salt-master-run-compose)
    if [ "$TRAVIS" = "true" ]; then
        docker_update
    fi
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
