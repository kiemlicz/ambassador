#!/usr/bin/env bash

source .env
source .travis/common.sh

case "$1" in
docker)
  docker tag "$BASE_PUB_NAME-minion-$DOCKER_IMAGE:$TAG" "$DOCKER_USERNAME/$BASE_PUB_NAME-minion-$DOCKER_IMAGE:$TAG"
  docker tag "$BASE_PUB_NAME-master-$DOCKER_IMAGE:$TAG" "$DOCKER_USERNAME/$BASE_PUB_NAME-master-$DOCKER_IMAGE:$TAG"

  docker_push "$DOCKER_USERNAME/$BASE_PUB_NAME-minion-$DOCKER_IMAGE:$TAG"
  docker_push "$DOCKER_USERNAME/$BASE_PUB_NAME-master-$DOCKER_IMAGE:$TAG"
  ;;
chart)
  echo "Uploading contents of: $BUILD_DIR"
  ls -al $BUILD_DIR/
  ;;
esac