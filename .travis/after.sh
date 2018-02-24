#!/usr/bin/env bash

case "$TEST_CASE" in
salt-master-run)
    echo "scanning compose's containers"
    exit $(docker-compose -f .travis/"$DOCKER_IMAGE"/docker-compose.yml --project-directory=. ps -q | xargs docker inspect -f '{{ .State.ExitCode }}' | grep -v 0 | wc -l | tr -d ' ')
    ;;
*)
esac
