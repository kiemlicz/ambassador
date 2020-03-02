pkgs:
  dist_upgrade: False
  os_packages:
    - socat
    - python3-setuptools
  pip3_user: travis
  pip3_packages:
    - testinfra
    - kubernetes

docker:
    version: "18.06.1~ce~3-0~ubuntu"

kubernetes:
  config:
    locations:
      - "/home/travis/.kube/config"
  user: travis

helm:
  owner: travis
  repositories:
    - name: elastic
      url: https://helm.elastic.co
