#!/usr/bin/env bash

case "$TEST_CASE" in
salt-masterless-dry|salt-masterless-run)
    # privileged mode is necessary for e.g. setting: net.ipv4.ip_forward
    docker run --privileged "$DOCKER_IMAGE"
    ;;
salt-master-run)
    docker-compose -f .travis/"$DOCKER_IMAGE"/docker-compose.yml --project-directory=. run master minion1 minion2 minion3
    ;;
ambassador-run)
    docker run -h $TEST_FQDN "$DOCKER_IMAGE"
    ;;
esac
