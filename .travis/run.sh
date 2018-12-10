#!/usr/bin/env bash

case "$TEST_CASE" in
salt-masterless-run)
    # privileged mode is necessary for e.g. setting: net.ipv4.ip_forward or running docker in docker
    docker run --name "ambassador-salt-masterless-run-$TRAVIS_JOB_NUMBER" --privileged "$DOCKER_IMAGE"
    ;;
salt-master-run-compose)
    # --exit-code-from master isn't the way to go as implies --abort-on-container-exit
    docker-compose -f .travis/docker-compose.yml --project-directory=. --no-ansi up --no-build --no-recreate
    ;;
salt-master-run-k8s)
    # --exit-code-from master isn't the way to go as implies --abort-on-container-exit
    kubectl apply -f .travis/k8s-deployment.yaml
    while kubectl get pods -o jsonpath='{range .items[?(@.metadata.labels.app == "salt-master" )]}{@.status.phase}' 2>&1 | grep -q "Running"; do
        echo "k8s still works:"
        kubectl get pods
        sleep 60
    done
    ;;
esac
