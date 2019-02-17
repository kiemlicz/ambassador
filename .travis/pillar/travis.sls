pkgs:
  dist_upgrade: False
  pip_packages:
    - kubernetes

docker:
    version: "18.06.1~ce~3-0~ubuntu"

kubernetes:
  config:
    locations:
      - "/root/.kube/config"
      - "/home/travis/.kube/config"
  user: travis

helm:
  owner: travis
