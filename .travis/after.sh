#!/usr/bin/env bash

case "$TEST_CASE" in
salt-master-run-compose)
    echo "scanning compose's containers"
    exit $(docker-compose -f .travis/docker-compose.yml --project-directory=. ps -q | xargs docker inspect -f '{{ .State.ExitCode }}' | grep -v 0 | wc -l | tr -d ' ')
    ;;
salt-master-run-k8s)
    echo "scanning k8s salt-master"
    ret=$(kubectl get pod -n provisioning salt-master -o jsonpath="'{range @.status.containerStatuses[?(@.name=='salt-master')]}{@.state.terminated.exitCode}{end}'" | tr -d "'")
    echo "salt-master exit code: $ret"
    exit $ret
    ;;
*)
esac
