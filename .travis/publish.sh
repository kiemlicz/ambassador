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
  # Temporary dir for storing new packaged charts and index files
  BUILD_DIR=$(mktemp -d)

  helm dependency update deployment/salt
  helm package -d $BUILD_DIR deployment/salt
  # Indexing of charts
  if [ -f index.yaml ]; then
    helm repo index --url $GH_URL --merge index.yaml .
  else
    helm repo index --url $GH_URL .
  fi

  # List all the contents that we will push
  ls $BUILD_DIR/

  # Clone repository and empty target branch
  SHA=$(git rev-parse --verify HEAD)
  SSH_REPO=${REPO_URL/https:\/\/github.com\//git@github.com:}
  git clone $REPO_URL .local
  cd .local
  git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH
  cd ..
  rm -rf .local/* || exit 0

  cp $BUILD_DIR/* .local/
  cd .local

  # todo Deploy if there are some changes, git diff won't detect newly added files (since they are staged)
  echo "Publishing Charts"
  # Add all new files to staging phase and commit the changes
  git config user.name "Travis CI"
  git config user.email "travis@travis-ci.org"
  git add -A .
  git status
  git commit -m "Travis deploy $SHA"
  # We can push.
  git push "$SSH_REPO"
  ;;
esac
