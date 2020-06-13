kubernetes:
  network:
    provider: flannel
    cidr: "10.244.0.0/16"
  master:
    isolate: True
  nodes:
    masters:
      - node1
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
    masters:
      - node1
      - node2
    workers:
      - node3
      - node4
