server:
  'syntax-test-host':
    - os
    - os.pkgs.unattended
    - samba
    - users
    - mail
    - minion
    - minion.upgrade
    - lxc
    - java
    - erlang
    - rebar
    - scala
    - gradle
    - maven
    - sbt
    - intellij
    - grafana
    - influxdb
    - virtualbox
    - docker
    - docker.compose
    - keepalived
    - lvs.director
    - lvs.realserver
    - kvm
    - kubernetes.client
    - kubernetes.minikube
# no point in syntax tests as won't work on empty pillar
#    - kubernetes.master
    - kubernetes.worker
    - kubernetes.helm
    - vagrant
  'base-host':
    - os
    - os.pkgs.unattended
    - samba
    - users
    - mail
# cannot test in Docker, must be tested on regular VM
#    - lxc
  'server-host':
    - os
    - os.pkgs.unattended
    - samba
    - users
    - java
    - scala
    - sbt
    - intellij
# test/debug states, use CONTEXT=debug
#  'debug-host':
#    - minion.debug.1
#    - minion.debug.2
