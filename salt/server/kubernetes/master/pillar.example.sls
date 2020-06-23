kubernetes:
  network:
    provider: flannel
    cidr: "10.244.0.0/16"
  master:
    isolate: True
  nodes:
    masters:
      - {{ salt['grains.get']('id') }}
    workers:
      - node2
---
kubernetes:
  network:
    provider: flannel
    cidr: "10.244.0.0/16"
  master:
    isolate: False
    reset: True
  nodes:
    master_vip: 1.2.3.4/32
    masters:
      - {{ salt['grains.get']('id') }}
      - node2
    workers:
      - node3
      - node4
