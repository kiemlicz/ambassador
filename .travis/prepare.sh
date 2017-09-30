#!/usr/bin/env bash

set -e
if [ -z "$DOCKER_IMAGE" ]; then
    >&2 echo "Docker image must be provided" #stderror print
    exit 1
fi

case "$TEST_CASE" in
salt-masterless-dry)
    docker build -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/Dockerfile .
    ;;
salt-masterless-run)
    docker build --build-arg=LOG_LEVEL="${LOG_LEVEL-info}" -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/Dockerfile.run .
    ;;
ambassador-run)
    docker build --build-arg=FQDN="$TEST_FQDN" -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/Dockerfile.ambassador .
    ;;
esac
