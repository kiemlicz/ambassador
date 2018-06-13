#!/usr/bin/env bash

case "$TEST_CASE" in
salt-masterless-run)
    # privileged mode is necessary for e.g. setting: net.ipv4.ip_forward or running docker in docker
    docker run --name "ambassador-salt-masterless-run-$TRAVIS_JOB_NUMBER" --privileged "$DOCKER_IMAGE"
    ;;
salt-master-run)
    # --exit-code-from master isn't the way to go as implies --abort-on-container-exit
    docker-compose -f .travis/docker-compose.yml --project-directory=. --no-ansi up --no-build --no-recreate
    ;;
ambassador-run)
    #docker run --name "ambassador-run-$TRAVIS_JOB_NUMBER" --privileged -h $TEST_FQDN "$DOCKER_IMAGE"
    /opt/run.sh
    ;;
esac
