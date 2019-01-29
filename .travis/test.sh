#!/usr/bin/env bash

set -e

k8s_log_error() {
    echo "Error during kubernetes deployment"
    kubectl get all --all-namespaces
    echo "Events:"
    kubectl get events --all-namespaces
    echo "Salt master info"
    kubectl describe pod -l app=salt-master -n provisioning
    echo "Salt minion info"
    kubectl describe pod -l name=salt-minion -n provisioning
}

case "$TEST_CASE" in
salt-masterless-run)
    # privileged mode is necessary for e.g. setting: net.ipv4.ip_forward or running docker in docker
    name="ambassador-salt-masterless-run-$TRAVIS_JOB_NUMBER"
    docker run --name $name --hostname "$SALTENV-host" --privileged "$DOCKER_IMAGE"
    ;;
salt-master-run-compose)
    # --exit-code-from master isn't the way to go as implies --abort-on-container-exit
    docker-compose -f .travis/docker-compose.yml --project-directory=. up --no-build --no-recreate
    ;;
salt-master-run-k8s)
    echo "Starting kubernetes deployment"
    trap k8s_log_error EXIT TERM INT
    kubectl apply -f .travis/k8s-deployment.yaml
    # wait until salt-master and minion containers are running
    #kubectl wait -n provisioning deployment/salt-master --for condition=available --timeout=3m
    kubectl wait -n provisioning deployment/rsyslog --for condition=available --timeout=2m
    echo "Deployment ready:"
    kubectl get all -n provisioning
    logger=$(kubectl get pod -l app=rsyslog -n provisioning -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    kubectl logs -n provisioning $logger -f &
    while sleep 5m; do echo -e "\nEvents:$(kubectl get events --all-namespaces)\nStatus:$(kubectl get all --all-namespaces)"; done &

    #kubectl wait won't detect if the pod failed
    #kubectl wait -n provisioning --for=delete pod/salt-master --timeout=60m
    while kubectl get pod -n provisioning salt-master -o jsonpath="'{range @.status.conditions[?(@.type=='Ready')]}{@.status}{end}'" | grep -q "True"; do
        sleep 1m
    done
    sleep 1m # for fluentd...
    echo "Deployment finished"
    ;;
esac
