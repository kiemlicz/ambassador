#!/usr/bin/env bash

set -e

k8s_log_error() {
    echo -e "\n####################\n\nERROR DURING KUBERNETES DEPLOYMENT\n\n####################\n"
    kubectl get all --all-namespaces
    echo -e "\n[ERROR]Events:"
    kubectl get events --all-namespaces
    echo -e "\n[ERROR] Pods info"
    kubectl describe pods -n salt-provisioning
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

    #kubectl apply -f .travis/k8s-deployment.yaml
    helm install .travis/chart -n salt

    # wait until salt-master and minion containers are running and ready (ready == minion synchronized)
    kubectl wait -n salt-provisioning pod -l name=salt-minion --for condition=ready --timeout=5m
    echo "Deployment ready:"
    kubectl get all -n salt-provisioning

    logger=$(kubectl get pod -l app=rsyslog -n salt-provisioning -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    echo "logs from: $logger"
    kubectl logs -n salt-provisioning $logger -f &
    while sleep 5m; do echo -e "\nEvents:$(kubectl get events --all-namespaces)\nStatus:$(kubectl get all --all-namespaces)"; done &

    # tests here

    #kubectl wait won't detect if the pod failed
    #kubectl wait -n provisioning --for=delete pod/salt-master --timeout=60m
    while kubectl get pod -n salt-provisioning -l app=salt-master -o jsonpath="'{range @.status.conditions[?(@.type=='Ready')]}{@.status}{end}'" | grep -q "True"; do
        sleep 1m
    done
    sleep 1m # for fluentd...
    echo "Deployment finished"
    ;;
esac
