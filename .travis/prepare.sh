#!/usr/bin/env bash

set -e
if [ -z "$DOCKER_IMAGE" ]; then
    >&2 echo "Docker image must be provided" #stderror print
    exit 1
fi

docker_compose_update() {
    local docker_compose_version=1.18.0

    docker-compose --version
    sudo rm /usr/local/bin/docker-compose
    curl -L https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m` > docker-compose
    chmod +x docker-compose
    sudo mv docker-compose /usr/local/bin
    docker-compose --version
    docker --version
}

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce

case "$TEST_CASE" in
salt-masterless-dry)
    docker build --build-arg=SALT_VER="2017.7.3" -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/dry/Dockerfile .
    ;;
salt-masterless-run)
    docker build --build-arg=SALT_VER="2017.7.3" --build-arg=LOG_LEVEL="${LOG_LEVEL-info}" --build-arg=SALTENV="$SALTENV" -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/masterless/Dockerfile .
    ;;
salt-master-run)
    docker_compose_update
    docker-compose -f .travis/"$DOCKER_IMAGE"/docker-compose.yml --project-directory=. up --no-start
#    --build-arg LOG_LEVEL="${LOG_LEVEL-info}" --build-arg SALTENV="$SALTENV"
    ;;
ambassador-run)
    docker build --build-arg=FQDN="$TEST_FQDN" -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/run/Dockerfile .
    ;;
esac
