# Self-hosted test environment
Due to numerous docker limitations tests should be performed in LXC container or even better: dedicated VMs

The most common way is to use [kitchen-salt](https://github.com/saltstack/kitchen-salt), the Kitchen plugin that provides Salt provisioner

Following directory contains setup of kitchen test **runner** (the machine that will be running tests).  
Basically it spawns LXC container (using Vagrant) and provisions it using Ambassador (create your own pillar configuration)

Setup: `sudo SHELL=/bin/bash python3 install.py --name <name> --ifc <interface> --configs <the config> <the other config> [--kdbx the.db.kdbx] [--kdbx-pass thepassword] [--kdbx-key the.key]`

The setup eventually runs `salt-call --local state.highstate` thus provide desired states:
```
> cat top.sls
server:
  'zeus':
    - os
    - mail
    - vagrant
    - users
```
Example `kitchen.local.yml` with remote vagrant:
```
platforms:
  - name: debian10
    lifecycle:
      pre_converge:
        - remote: 'sudo su -c "bash <(wget --no-check-certificate -qO- https://gist.githubusercontent.com/kiemlicz/1aa8c2840f873b10ecd744bf54dcd018/raw/1fb26207f7d9665989fc7019b1c0ac919383331a/setup_salt_requisites.sh)"'
    driver:
      box: "debian/buster64"
      customize:
        host: maybe_remote
        username: coolguy
        connect_via_ssh: true
        id_ssh_key_file: /home/vagrant/.ssh/id_rsa
        uri: "qemu+ssh://coolguy@maybe_remote/system"
      ssh:
        insert_key: false
    driver_config:
      run_command: /lib/systemd/systemd
suites:
  - name: default
    provisioner:
      salt_minion_extra_config:
        # the tested VM minion config options like:
        custom_sdb:
           driver: custom_sdb
        ext_pillar: []
        gitfs_remotes: {}
        # in general: minion config that will be merged with minion.erb
      pillars:
        top.sls:
          base:
            '*':
              - overrides
        overrides.sls:
          some:
            extra:
              pillar: "to add"
```
Then from runner, run tests with: `.test/runner.sh`

## Running tests locally
```
#!/usr/bin/env bash

export KUBECTL_VER="v1.17.3"
export DOCKER_IMAGE="debian-buster"
export BASE_IMAGE_TAG="buster"
export BASE_PUB_NAME="envoy"
export PIP3_KUBERNETES_VER="10.0.1"
export PIP3_PYGIT2_VER="1.0.3"
export CONTEXT="syntax-test"
export TEST="syntax"
export K8S_API_ENABLED=true
export SALTENV=server

docker rm salt-test || true
.travis/prepare.sh salt-test
# https://github.com/pytest-dev/pytest-xdist/issues/402

docker run \
   --name salt-test \
   --network=host \
   --hostname "$CONTEXT-host" \
   --privileged \
   "$BASE_PUB_NAME-salt-test-$DOCKER_IMAGE:latest" --log-level INFO --tests $TEST -n 1 -v
#docker run -it --entrypoint bash --name salt-test --network=host --hostname "$CONTEXT-host" --privileged "$BASE_PUB_NAME-salt-test-$DOCKER_IMAGE:latest"

```
