#!/usr/bin/env bash

set -e
if [ -z "$DOCKER_IMAGE" ]; then
    >&2 echo "Docker image must be provided" #stderror print
    exit 1
fi

case "$TEST_CASE" in
salt-masterless)
    docker build -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/Dockerfile .
    ;;
ambassador-run)
    docker build --build-arg CID="$TEST_FQDN" \
    -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/Dockerfile.ambassador .
    ;;
esac
