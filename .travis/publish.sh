#!/usr/bin/env bash


# $1 tag name
docker_push() {
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    docker commit $1 kiemlicz/ambassador:$1
    docker push kiemlicz/ambassador:$1
}

case "$TEST_CASE" in
salt-masterless-run)
    if [ $TRAVIS_TEST_RESULT -eq 0 ]; then
        docker_push "salt-masterless-$TRAVIS_JOB_NUMBER"
    else
        docker_push "salt-masterless-$TRAVIS_JOB_NUMBER-failed"
    fi
    ;;
salt-master-run)
    echo "salt-master-run publish is disabled"
    ;;
ambassador-run)
    if [ $TRAVIS_TEST_RESULT -eq 0 ]; then
        docker_push "ambassador-run-$TRAVIS_JOB_NUMBER"
    else
        docker_push "ambassador-run-$TRAVIS_JOB_NUMBER-failed"
    fi
    ;;
esac
