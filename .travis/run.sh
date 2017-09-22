#!/usr/bin/env bash

case "$TEST_CASE" in
salt-masterless-dry|salt-masterless-run)
    # privileged mode is necessary for e.g. setting: net.ipv4.ip_forward
    docker run --privileged "$DOCKER_IMAGE"
    ;;
ambassador-run)
    docker run -h $TEST_FQDN "$DOCKER_IMAGE"
    ;;
esac
