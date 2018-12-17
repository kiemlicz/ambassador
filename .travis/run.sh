#!/usr/bin/env bash


k8s_log_error() {
    echo "Error during kubernetes deployment"
    kubectl get all --all-namespaces
    echo "Events:"
    kubectl get events --all-namespaces
}

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
    echo "Starting kubernetes deployment"
    trap k8s_log_error EXIT TERM INT
    echo "trap setup complete"
    kubectl apply -f .travis/k8s-deployment.yaml
    # wait until salt-master and minion containers are running
    kubectl wait -n provisioning deployment/salt-master --for condition=available --timeout=120s
    kubectl wait -n provisioning deployment/rsyslog --for condition=available --timeout=120s
    echo "Deployment ready:"
    kubectl get all -n provisioning
    logger=$(kubectl get pod -l app=rsyslog -n provisioning -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    #kubectl wait -n provisioning --for=delete deployment/salt-master --timeout=60m
    kubectl logs -n provisioning $logger -f
    echo "Deployment finished"
    ;;
esac
