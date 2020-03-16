base:
  'base-host':
    - os
    - os.pkgs.unattended
    - samba
    - users
    - mail
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
    - kubernetes.master
    - kubernetes.worker
    - kubernetes.helm
    - vagrant
  'base-host':
    - os
    - os.pkgs.unattended
    - samba
    - users
    - mail
