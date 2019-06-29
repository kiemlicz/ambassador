kubernetes:
  network:
    provider: flannel
    cidr: "10.244.0.0/16"
  master:
    isolate: True
---
kubernetes:
  network:
    provider: flannel
    cidr: "10.244.0.0/16"
  master:
    isolate: False
    reset: True
