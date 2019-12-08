#!/usr/bin/env bash

set -e

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

case "$1" in
dry)
    while sleep 9m; do echo "=====[ $SECONDS seconds still running ]====="; done &
    docker run --privileged "envoy-dry-test-$DOCKER_IMAGE:$TAG"
    result=$?
    kill %1
    # in order to return proper exit code instead of always 0 (of kill command)
    exit $result
    ;;
masterless)
    # privileged mode is necessary for e.g. setting: net.ipv4.ip_forward or running docker in docker
    name="ambassador-salt-masterless-run-$TRAVIS_JOB_NUMBER"
    while sleep 9m; do echo "=====[ $SECONDS seconds still running ]====="; done &
    docker run --name $name --hostname "$CONTEXT-host" --privileged "masterless-test-$DOCKER_IMAGE:$TAG" 2>&1 | tee output
    exit_code=${PIPESTATUS[0]}  # gets the exit code of first (piped) process
    kill %1
    if [[ "$exit_code" != 0 ]]; then
        echo "found failures"
        exit $exit_code
    fi
    result=$(awk '/^Failed:/ {if($2 != "0") print "fail"}' output)
    if [[ "$result" == "fail" ]]; then
        echo "found failures"
        exit 3
    fi
    ;;
salt-master-run-compose)
    # --exit-code-from master isn't the way to go as implies --abort-on-container-exit
    docker-compose -f .travis/docker-compose.yml --project-directory=. up --no-build --no-recreate
    echo "scanning compose's containers"
    exit $(docker-compose -f .travis/docker-compose.yml --project-directory=. ps -q | xargs docker inspect -f '{{ .State.ExitCode }}' | grep -v 0 | wc -l | tr -d ' ')
    ;;
salt-master-run-k8s)
    echo -e "Starting kubernetes deployment\n$(date)\n"
    trap k8s_log_error EXIT TERM INT

    helm dependency update deployment/salt
    kubectl create namespace salt-provisioning
    helm install salt deployment/salt -f .travis/travis_values.yaml --namespace salt-provisioning --wait --timeout=300s

    # wait for logger first, not sure if --wait waits for dependencies
    #kubectl wait -n salt-provisioning pod -l app=logstash --for condition=ready --timeout=5m
    logger=$(kubectl get pod -l app=logstash -n salt-provisioning -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    echo -e "starting logs from: $logger"
    kubectl -n salt-provisioning logs -f $logger &

    python3 .travis/k8s-test.py salt-provisioning

    #while sleep 5m; do echo -e "\nEvents:$(kubectl get events --all-namespaces)\nStatus:$(kubectl get all --all-namespaces)"; done &

    ##echo -e "\nTest 1: should accept new minion\n"
    ##kubectl -n salt-provisioning delete pod -l name=salt-minion
    ##kubectl -n salt-provisioning wait pod -l name=salt-minion --for condition=ready --timeout=5m
# this will still contain old minion that will fail the ping
#    echo "Pinging minions"
#    kubectl -n salt-provisioning exec -it $(kubectl -n salt-provisioning get pod -l name=salt-master -o jsonpath='{.items[0].metadata.name}') -- salt '*' test.ping

    ##echo -e "\nTest 2: should work after master crash\n"
    ##kubectl -n salt-provisioning delete pod -l name=salt-master
    ##kubectl -n salt-provisioning wait pod -l name=salt-master --for condition=ready --timeout=5m

    # the minion must first re-auth to master that got down, will do that after auth_timeout (?) + thorium re-scan
    # it will finally clean the old keys but honestly, why does it take so long?
    ##sleep 180
    ##echo -e "\nAfter 3 min sleep: listing who's up"
    master=$(kubectl -n salt-provisioning get pod -l name=salt-master -o jsonpath='{.items[0].metadata.name}')
    kubectl -n salt-provisioning exec -it $master -- salt-key -L
    kubectl -n salt-provisioning exec -it $master -- salt-run manage.up
    echo -e "\nSalt-master POD logs:\n"
    kubectl -n salt-provisioning logs $master
# fixme
# this will still contain old minion that will fail the ping
#    echo "Pinging minions"
#    kubectl -n salt-provisioning exec -it $(kubectl -n salt-provisioning get pod -l name=salt-master -o jsonpath='{.items[0].metadata.name}') -- salt '*' test.ping

    echo "Deployment finished"
    ;;
esac
