#!/usr/bin/env bash

set -e
if [ -z "$DOCKER_IMAGE" ]; then
    >&2 echo "Docker image must be provided" #stderror print
    exit 1
fi

COMPOSE_VER="1.22.0"
KUBECTL_VER="v1.13.0"
MINIKUBE_VER="v0.30.0"

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

kubectl_install() {
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VER/bin/linux/amd64/kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
}

minikube_install() {
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/$MINIKUBE_VER/minikube-linux-amd64
    chmod +x minikube
    sudo mv minikube /usr/local/bin/
    sudo minikube start --vm-driver=none
    minikube update-context
    echo "Waiting for nodes:"
    kubectl get nodes
    #wait until nodes report as ready
    JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; \
    until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done
    eval $(minikube docker-env)
    echo "minikube setup complete"
}

docker_build() {
    if [ -z $1 ]; then
        >&2 echo "Dockerfile path missing"
        exit 4
    fi
    docker build \
        --build-arg=salt_ver=$SALT_VER \
        --build-arg=log_level="${LOG_LEVEL-info}" \
        --build-arg=saltenv="$SALTENV" \
        --build-arg=pillarenv="$PILLARENV" \
        --build-arg=kubectl_ver="$KUBECTL_VER" \
        -t "${2-$DOCKER_IMAGE}" \
        -f $1 .
}

case "$TEST_CASE" in
salt-masterless-run)
    docker_update
    docker_build .travis/"$DOCKER_IMAGE"/masterless/Dockerfile
    ;;
salt-master-run-compose)
    docker_update
    docker_compose_update
    docker-compose -f .travis/docker-compose.yml --project-directory=. --no-ansi up --no-start
    ;;
salt-master-run-k8s)
    kubectl_install
    minikube_install
    #create PV paths manually
    sudo mkdir -p /mnt/data/r0 /mnt/data/r1 /mnt/data/r2 /mnt/data/r3 /mnt/data/r4 /mnt/data/r5
    # build images that are used for provisioning (salt master's and minion's)
    # only one of each is required per one node cluster
    docker_build .travis/"$DOCKER_IMAGE"/master/Dockerfile salt_master
    docker_build .travis/"$DOCKER_IMAGE"/minion/k8s/Dockerfile salt_minion
    ;;
esac
