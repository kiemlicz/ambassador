{% from "kubernetes/network/map.jinja" import kubernetes with context %}


include:
  - kubernetes.network.{{ kubernetes.network.provider }}
