#!/usr/bin/env bash

# if the git tag is present then it will be used as docker tag
TAG=$(echo "$GITHUB_REF" | sed -ne 's|refs/tags/\(.*\)|\1|p')
if [ -z "$TAG" ]; then
  TAG="latest"
fi

if [ "$CI" = "true" ]; then
  PODMAN_EXE="sudo podman"
else
  PODMAN_EXE="podman"
fi

BASE_IMAGE=$(echo $DOCKER_IMAGE | cut -d: -f1)

podman_clear() {
  local container_name="$1"
  echo "Stopping and removing $container_name if running"
  $PODMAN_EXE stop $container_name || true
  $PODMAN_EXE rm $container_name || true
}

podman_build() {
  if [ "$CI" = "true" ]; then
    local python_exe="sudo python3"
  else
    local python_exe="python3"
  fi
  $python_exe installer/install.py --to podman --name tester --base-os $DOCKER_IMAGE --docker-tag "${2}" --docker-target "$1"
}

docker_build() {
  #    if [ -z $1 ]; then
  #        >&2 echo "Dockerfile target missing"
  #        exit 4
  #    fi
  #    # fixme no longer needed ?
  #    build_args=(
  #        "--build-arg=salt_ver=$SALT_VER"
  #        "--build-arg=pip3_ver=$PIP3_VER"
  #        "--build-arg=master_user=${MASTER_USER-root}"
  #        "--build-arg=minion_user=${MINION_USER-root}"
  #        "--build-arg=log_level=${LOG_LEVEL-info}"
  #        "--build-arg=saltenv=${SALTENV-base}"
  #        "--build-arg=kubectl_ver=$KUBECTL_VER"
  #        "--build-arg=pip3_pygit2_ver=$PIP3_PYGIT2_VER"
  #        "--build-arg=pip3_kubernetes_ver=$PIP3_KUBERNETES_VER"
  #        "--build-arg=api_enabled=${API_ENABLED-false}"
  #        "--build-arg=k8s_api_enabled=${K8S_API_ENABLED-false}"
  #    )
  #    if [ ! -z $BASE_IMAGE_TAG ]; then
  #        build_args+=("--build-arg=tag=$BASE_IMAGE_TAG")
  #    fi
  #    DOCKER_BUILDKIT=1 docker build \
  #        "${build_args[@]}" \
  #        --target $1 \
  #        -t "${2-$DOCKER_IMAGE}" \
  #        -f deployment/docker/"$DOCKER_IMAGE"/Dockerfile .
  if [ "$CI" = "true" ]; then
    local python_exe="sudo python3"
  else
    local python_exe="python3"
  fi
  $python_exe installer/install.py --to docker --name tester --base-os $DOCKER_IMAGE --docker-tag "$2" --docker-target "$1"
}

# $1 full repo/name:tag
docker_push() {
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  docker push "$1"
}

#fixme change env names
#fixme?! use install script? install --to this host?
salt_install() {
  sudo apt-get update && sudo apt-get install -y curl python3-setuptools python3-pip rustc
  sudo -H pip3 install pip~=21.0.1 setuptools-rust~=0.12.1
  sudo -H pip3 install -r $GITHUB_WORKSPACE/config/requirements.txt --ignore-installed
  sudo mkdir -p /etc/salt/minion.d/
  # do i need this cp ???
  sudo cp ${1-".travis/config/masterless.conf"} /etc/salt/minion.d/ # fixme no longer exists
  sudo ln -s $GITHUB_WORKSPACE/salt /srv/salt
  #fixme rename k8s to something more meaningful (this is the minikube setup)
  sudo ln -s $GITHUB_WORKSPACE/.github/pillar/k8s /srv/pillar
  curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com
  sudo sh /tmp/bootstrap-salt.sh -x python3 -n stable
}

minikube_ready() {
  echo "Waiting for nodes..."
  kubectl get nodes --show-labels
  # since minikube 1.7.X the node name is equal to hostname
  kubectl wait nodes/$(hostname) --for condition=ready
  echo "minikube setup complete"
}

minikube_install() {
  sudo salt-call --local state.apply kubernetes.client saltenv=server
  sudo salt-call --local state.apply kubernetes.minikube saltenv=server
  sudo salt-call --local state.apply kubernetes.helm saltenv=server
  minikube_ready
}

still_running() {
  minutes=0
  limit=60
  while docker ps | grep -q $1; do
    echo -n -e " \b"
    if [ $minutes == $limit ]; then
      break
    fi
    minutes=$((minutes + 1))
    sleep 60
  done
}
