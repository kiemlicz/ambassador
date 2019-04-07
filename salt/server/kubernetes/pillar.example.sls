#kubernetes may require concrete docker version, set with:
#docker:
#    version: "18.06.1~ce~3-0~ubuntu"
#    version: "18.06.1~ce~3-0~debian"

kubernetes:
  network:
    provider: flannel
    cidr: "10.244.0.0/16"
  master:
    isolate: True
