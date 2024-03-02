{% from "kubernetes/csi/map.jinja" import kubernetes with context %}
{%- from "_common/util.jinja" import retry with context %}

include:
  - kubernetes.csi.iscsi
  - os.lvm

# OpenEBS provisioning as part of Flux as maintaining Helm via Salt is terrible
