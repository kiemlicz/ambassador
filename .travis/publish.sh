#!/usr/bin/env bash

source .travis/common.sh

docker tag "envoy-minion-$DOCKER_IMAGE:$TAG" "$DOCKER_USERNAME/envoy-minion-$DOCKER_IMAGE:$TAG"
docker tag "envoy-master-$DOCKER_IMAGE:$TAG" "$DOCKER_USERNAME/envoy-master-$DOCKER_IMAGE:$TAG"

docker_push "$DOCKER_USERNAME/envoy-minion-$DOCKER_IMAGE:$TAG"
docker_push "$DOCKER_USERNAME/envoy-master-$DOCKER_IMAGE:$TAG"
