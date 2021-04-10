#!/usr/bin/env bash

set -e

source .env
source .travis/common.sh

k8s_log_error() {
    local rv=$?
    case $rv in
    0)
        echo "no error"
    ;;
    *)
        echo -e "\n####################\n\nERROR DURING KUBERNETES DEPLOYMENT\n$(date)\n####################\n"
        kubectl get all --all-namespaces
        echo -e "\n[ERROR]Events:"
        kubectl get events --all-namespaces
        echo -e "\n[ERROR] Pods info"
        kubectl -n salt-provisioning describe pods
        echo -e "\n[ERROR] Master logs"
        kubectl -n salt-provisioning logs -l name=salt-master
        echo -e "\n[ERROR] Minion logs"
        kubectl -n salt-provisioning logs -l name=salt-minion
        ;;
    esac
}

while sleep 9m; do echo "=====[ $SECONDS seconds still running ]====="; done &

case "$1" in
salt-test)
    # privileged mode is necessary for e.g. setting: net.ipv4.ip_forward or running docker in docker
    # check if https://stackoverflow.com/questions/33013539/docker-loading-kernel-modules is possible on travis
    opts="--tests $TEST --log-level ${TEST_LIVE_LOG-INFO}"
    # without -n the xdist is disabled and live log is streamed
    if [ -z "$TEST_LIVE_LOG" ]; then
      echo "pytest xdist enabled"
      opts="$opts -n $(nproc)"
    fi
    docker run --name salt-test --network=host --hostname "$CONTEXT-host" --privileged "$BASE_PUB_NAME-salt-test-$DOCKER_IMAGE:$TAG" $opts
    result=$?
    kill %1  # kill the while loop
    # in order to return proper exit code instead of always 0 (of kill command)
    exit $result
    ;;
salt-master-run-k8s)
    echo -e "Starting kubernetes deployment\n$(date)\n"
    trap k8s_log_error EXIT TERM INT

    ns="salt-provisioning"
    helm dependency update deployment/salt
    kubectl create namespace $ns
    helm install salt deployment/salt -f .travis/travis_values.yaml --namespace $ns --wait --timeout=300s

    # deployment tests
    python3 .travis/k8s-test.py $ns

    # fixme this is terrible, maybe come up with dedicated test image?
    # upload and run salt tests
    master=$(kubectl -n $ns get pod -l app=salt,role=master -o jsonpath='{.items[0].metadata.name}')
    kubectl -n $ns cp .travis/k8s-salt-test.py $ns/$master:/opt/
    kubectl -n $ns exec $master -- pip3 install timeout_decorator
    kubectl -n $ns exec $master -- python3 /opt/k8s-salt-test.py

    # wait for logger first, not sure if --wait waits for dependencies
    #kubectl wait -n salt-provisioning pod -l app=logstash --for condition=ready --timeout=5m
    logger=$(kubectl get pod -l app=logstash -n $ns -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    echo -e "starting logs from: $logger"
    kubectl -n $ns logs -f $logger &

    master=$(kubectl -n $ns get pod -l name=salt-master -o jsonpath='{.items[0].metadata.name}')
    echo -e "\nSalt-master POD logs:\n"
    kubectl -n $ns logs $master

    echo "Deployment testing finished"
    ;;
*)
    echo "No such test"
  ;;
esac
