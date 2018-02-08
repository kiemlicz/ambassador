#!/usr/bin/env bash

case "$TEST_CASE" in
salt-masterless-dry|salt-masterless-run)
    # privileged mode is necessary for e.g. setting: net.ipv4.ip_forward or running docker in docker
    docker run --privileged "$DOCKER_IMAGE"
    ;;
salt-master-run)
    # --exit-code-from master isn't the way to go as implies --abort-on-container-exit
    docker-compose -f .travis/"$DOCKER_IMAGE"/docker-compose.yml --project-directory=. up --no-build --no-recreate
    exit $(docker-compose -f .travis/"$DOCKER_IMAGE"/docker-compose.yml --project-directory=. ps -q | \
        xargs docker inspect -f '{{ .State.ExitCode }}' | grep -v 0 | wc -l | tr -d ' ')
    ;;
ambassador-run)
    docker run --privileged -h $TEST_FQDN "$DOCKER_IMAGE"
    ;;
esac
