{%- from "kubernetes/cni/map.jinja" import kubernetes with context %}
{%- from "_common/util.jinja" import retry with context %}

kubernetes_cni:
  sysctl.present:
    - name: "net.bridge.bridge-nf-call-iptables"
    - value: 1
  cmd.run:
    - name: kubectl apply -f {{ kubernetes.cni.config.source }}
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
{{ retry(attempts=3)| indent(4) }}
    - require:
        - sysctl: kubernetes_cni
