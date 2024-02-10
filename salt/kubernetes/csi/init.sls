{% from "kubernetes/csi/map.jinja" import kubernetes with context %}


include:
  - kubernetes.csi.{{ kubernetes.csi.provider }}
