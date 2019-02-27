pkgs:
  dist_upgrade: False
  os_packages:
    - socat
  pip_packages:
    - pyyaml
    - cryptography
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
