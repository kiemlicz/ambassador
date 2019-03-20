#!/usr/bin/env bash

set -e

k8s_log_error() {
    echo -e "\n####################\n\nERROR DURING KUBERNETES DEPLOYMENT\n$(date)\n####################\n"
    kubectl get all --all-namespaces
    echo -e "\n[ERROR]Events:"
    kubectl get events --all-namespaces
    echo -e "\n[ERROR] Pods info"
    kubectl describe pods -n salt-provisioning
}

case "$TEST_CASE" in
salt-master-run-compose)
    # --exit-code-from master isn't the way to go as implies --abort-on-container-exit
    docker-compose -f .travis/docker-compose.yml --project-directory=. up --no-build --no-recreate
    ;;
salt-master-run-k8s)
    echo -e "Starting kubernetes deployment\n$(date)\n"
    trap k8s_log_error EXIT TERM INT

    helm install .travis/chart -n salt

    # wait for logger first
    kubectl wait -n salt-provisioning pod -l app=logstash --for condition=ready --timeout=5m
    logger=$(kubectl get pod -l app=logstash -n salt-provisioning -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    echo -e "\nlogs from: $logger"
    kubectl -n salt-provisioning logs -f $logger &

    # wait until salt-master and minion containers are running and ready (ready == minion synchronized)
    kubectl wait -n salt-provisioning pod -l name=salt-minion --for condition=ready --timeout=5m
    echo "Deployment ready:"
    kubectl get all -n salt-provisioning

    while sleep 5m; do echo -e "\nEvents:$(kubectl get events --all-namespaces)\nStatus:$(kubectl get all --all-namespaces)"; done &

    # tests here if any, wait for any event
    #kubectl wait won't detect if the pod failed
    #kubectl wait -n provisioning --for=delete pod/salt-master --timeout=60m
    #while kubectl get pod -n salt-provisioning -l app=salt-master -o jsonpath="'{range @.status.conditions[?(@.type=='Ready')]}{@.status}{end}'" | grep -q "True"; do
    #    sleep 1m
    #done
    #sleep 1m # for fluentd...

    echo "Deployment finished"
    ;;
esac
