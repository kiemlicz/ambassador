{%- from "kubernetes/cni/map.jinja" import kubernetes with context %}
{%- from "_common/util.jinja" import retry with context %}

# this is the only place to find options to configure https://github.dev/k3s-io/k3s
# navigate to pkg/daemons/config/types.go

kubernetes_cni:
  archive.extracted:
    - name: {{ kubernetes.cni.config.extract }}
    - source: {{ kubernetes.cni.config.source }}
    - skip_verify: True
    - enforce_toplevel: False
    - clean_parent: True
  cmd.run:
    - name: "{{ kubernetes.cni.config.extract }}/cilium install"
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
      - archive: kubernetes_cni
