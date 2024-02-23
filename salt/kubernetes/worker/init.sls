{%- from "kubernetes/worker/map.jinja" import kubernetes with context %}
{%- from "kubernetes/cni/map.jinja" import kubernetes as kubernetes_network with context %}

include:
  - {{ kubernetes.container.runtime }}
  - kubernetes.distro.{{kubernetes.distro}}.worker

kubernetes-worker-notification:
  test.succeed_without_changes:
    - name: Kubernetes worker setup completed
