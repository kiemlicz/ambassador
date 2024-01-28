{%- from "kubernetes/worker/map.jinja" import kubernetes with context %}
{%- from "kubernetes/network/map.jinja" import kubernetes as kubernetes_network with context %}

include:
  - {{ kubernetes.container.runtime }}
  - kubernetes.distro.{{kubernetes.distro}}.worker
