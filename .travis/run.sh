#!/usr/bin/env bash

case "$TEST_CASE" in
salt-masterless)
    docker run "$DOCKER_IMAGE"
    ;;
ambassador-run)
    docker run -h $TEST_FQDN "$DOCKER_IMAGE"
    ;;
esac
