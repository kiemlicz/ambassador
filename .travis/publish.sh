#!/usr/bin/env bash

case "$TEST_CASE" in
salt-masterless-run)
    echo "Unable to publish yet"
    ;;
salt-master-run)
    echo "Unable to publish yet"
    ;;
ambassador-run)
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    docker commit "ambassador-run-$TRAVIS_JOB_NUMBER" kiemlicz/ambassador:"ambassador-run-$TRAVIS_JOB_NUMBER"
    docker push kiemlicz/ambassador:"ambassador-run-$TRAVIS_JOB_NUMBER"
    ;;
esac
