{%- from "kubernetes/network/map.jinja" import kubernetes with context %}
{%- from "_common/util.jinja" import retry with context %}

kubernetes_network:
  archive.extracted:
    - name: {{ kubernetes.network.config.extract }}
    - source: {{ kubernetes.network.config.source }}
    - skip_verify: True
    - enforce_toplevel: False
    - clean_parent: True
  cmd.run:
    - name: "{{ kubernetes.network.config.extract }}/cilium install"
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
      - archive: kubernetes_network


# add this bpffs mount