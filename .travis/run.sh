#!/usr/bin/env bash

set -e

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
    kubectl apply -f .travis/k8s-deployment.yaml
    # wait until salt-master and minion containers are running
    kubectl wait -n provisioning deployment/salt-master --for condition=available --timeout=120s
    echo "Deployment ready:"
    kubectl get all -n provisioning
    while kubectl get pods -o jsonpath='{range .items[?(@.metadata.labels.app == "salt-master" )]}{@.status.phase}' 2>&1 | grep -q "Running"; do
        echo "k8s still works:"
        kubectl get all --all-namespaces
        sleep 60
    done
    ;;
esac
