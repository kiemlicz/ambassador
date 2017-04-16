#!/usr/bin/env bash

set -e
if [ -z "$DOCKER_IMAGE" ]; then
    >&2 echo "Docker image must be provided"
    exit 1
fi

docker build -t "$DOCKER_IMAGE" -f .travis/"$DOCKER_IMAGE"/Dockerfile .
