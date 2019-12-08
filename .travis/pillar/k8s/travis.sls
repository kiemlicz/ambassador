pkgs:
  dist_upgrade: False
  os_packages:
    - socat
  pip3_packages:
    - testinfra
    - kubernetes
#add pip3_user if still fails

docker:
    version: "18.06.1~ce~3-0~ubuntu"

kubernetes:
  config:
    locations:
      - "/home/travis/.kube/config"
  user: travis

helm:
  owner: travis
