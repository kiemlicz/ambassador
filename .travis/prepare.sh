#!/usr/bin/env bash

set -e
if [ -z "$DOCKER_IMAGE" ]; then
    >&2 echo "Docker image must be provided" #stderror print
    exit 1
fi

DOCKER_COMPOSE_VERSION=1.17.1

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce

case "$TEST_CASE" in
salt-masterless-dry)
    docker build -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/Dockerfile .
    ;;
salt-masterless-run)
    docker build --build-arg=LOG_LEVEL="${LOG_LEVEL-info}" --build-arg=SALTENV="$SALTENV" -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/Dockerfile.run .
    ;;
salt-master-run)
    docker-compose --version
    sudo rm /usr/local/bin/docker-compose
    curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > docker-compose
    chmod +x docker-compose
    sudo mv docker-compose /usr/local/bin
    docker-compose --version
    docker --version
    docker-compose -f .travis/"$DOCKER_IMAGE"/docker-compose.yml --project-directory=. up --no-start
#    --build-arg LOG_LEVEL="${LOG_LEVEL-info}" --build-arg SALTENV="$SALTENV"
    ;;
ambassador-run)
    docker build --build-arg=FQDN="$TEST_FQDN" -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/Dockerfile.ambassador .
    ;;
esac
