#!/usr/bin/env bash

case "$TEST_CASE" in
salt-masterless-dry|salt-masterless-run)
    # privileged mode is necessary for e.g. setting: net.ipv4.ip_forward or running docker in docker
    docker run --privileged "$DOCKER_IMAGE"
    ;;
salt-master-run)
    # --exit-code-from master isn't the way to go as implies --abort-on-container-exit
    docker-compose -f .travis/docker-compose.yml --project-directory=. --no-ansi up --no-build --no-recreate
    ;;
ambassador-run)
    docker run --privileged -h $TEST_FQDN "$DOCKER_IMAGE"
    ;;
esac
