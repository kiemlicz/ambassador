{% from "kubernetes/cni/map.jinja" import kubernetes with context %}


include:
  - kubernetes.cni.{{ kubernetes.cni.provider }}

# fixme assert DNS service works