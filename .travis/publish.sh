#!/usr/bin/env bash


# $1 container name
docker_push() {
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    if [ $TRAVIS_TEST_RESULT -eq 0 ]; then
        docker commit $1 kiemlicz/ambassador:$1
        docker push kiemlicz/ambassador:$1

    else
        docker commit $1 kiemlicz/ambassador:"$1-failed"
        docker push kiemlicz/ambassador:"$1-failed"
    fi
}

case "$TEST_CASE" in
salt-masterless-run)
    docker_push "ambassador-salt-masterless-run-$TRAVIS_JOB_NUMBER"
    ;;
salt-master-run-compose|salt-master-run-k8s)
    echo "salt-master-run publish is disabled"
    ;;
esac
