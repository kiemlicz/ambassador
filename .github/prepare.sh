#!/usr/bin/env bash

set -e
if [ -z "$DOCKER_IMAGE" ]; then
    >&2 echo "Docker image must be provided" #stderror print
    exit 1
fi

source .env
source .github/common.sh
# todo research if github supports docker API2 (paths)
case "$1" in
salt-test)
    container_name="salt-test"
    podman_clear $container_name
    if [ "$CI" = "true" ]; then
        # for publish purposes, by default not required anywhere else than Travis
        docker_build salt-minion "$BASE_PUB_NAME-minion-$BASE_IMAGE:$TAG"
        docker_build salt-master "$BASE_PUB_NAME-master-$BASE_IMAGE:$TAG"
    fi
    podman_build $container_name "$BASE_PUB_NAME-salt-test-$BASE_IMAGE:$TAG" \
      --configs config/ambassador-installer.conf .github/ambassador-test.conf \
      --requirements config/requirements.txt .github/requirements-test.txt \
      --extra .github/top.sls,/srv/salt/base/ \
      --extra .github/test,/opt
    nc -z 127.0.0.1 6379 || echo "Redis is not running - must be started before tests"
    ;;
salt-master-run-k8s)
    echo "The k8s deployment is deprecated"
    salt_install
    sudo salt-call --local saltutil.sync_all
    echo "ID: $(salt-call --local grains.get id)"
    minikube_install
    echo "hostname: $(hostname)"
    #create PV paths manually
    sudo mkdir -p /mnt/data/saltpki /mnt/data/saltqueue
    # build images that are used for provisioning (salt master's and minion's)
    # only one of each is required per one node cluster
    docker_build salt-master salt-master
    docker_build salt-minion salt-minion

    # Temporary dir for storing new packaged charts and index files
    mkdir $BUILD_DIR
    # clone existing charts
    git clone --single-branch --branch $CHART_BRANCH https://github.com/$GITHUB_REPOSITORY.git $BUILD_DIR
    helm dependency update deployment/salt
    helm package -d $BUILD_DIR deployment/salt
    cd $BUILD_DIR
    # Indexing of charts
    if [ -f index.yaml ]; then
      helm repo index --url $GH_URL --merge index.yaml .
    else
      helm repo index --url $GH_URL .
    fi
    ;;
*)
    echo "No such test"
  ;;
esac
