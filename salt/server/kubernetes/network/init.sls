{% from "kubernetes/network/map.jinja" import kubernetes with context %}


include:
  - kubernetes.network.{{ kubernetes.network.provider }}

# fixme assert DNS service works