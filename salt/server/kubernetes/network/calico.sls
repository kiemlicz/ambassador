{%- from "kubernetes/network/map.jinja" import kubernetes with context %}
{%- from "_common/util.jinja" import retry with context %}
kubernetes_network:
  cmd.run:
    - name: kubectl apply -f {{ kubernetes.network.source }}
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
{{ retry(attempts=3)| indent(4) }}
