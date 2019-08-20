#!/usr/bin/env bash

source .travis/common.sh

case "$1" in
docker)
  docker tag "envoy-minion-$DOCKER_IMAGE:$TAG" "$DOCKER_USERNAME/envoy-minion-$DOCKER_IMAGE:$TAG"
  docker tag "envoy-master-$DOCKER_IMAGE:$TAG" "$DOCKER_USERNAME/envoy-master-$DOCKER_IMAGE:$TAG"

  docker_push "$DOCKER_USERNAME/envoy-minion-$DOCKER_IMAGE:$TAG"
  docker_push "$DOCKER_USERNAME/envoy-master-$DOCKER_IMAGE:$TAG"
  ;;
chart)
  GH_URL=""
  # todo
  helm dependency update deployment/salt
  helm package -d deployment deployment/salt
  # Indexing of charts
  if [ -f index.yaml ]; then
    helm repo index --url ${GH_URL} --merge index.yaml .
  else
    helm repo index --url ${GH_URL} .
  fi
  ;;
esac