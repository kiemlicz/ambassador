{%- from "kubernetes/cni/map.jinja" import kubernetes with context %}
{%- from "_common/util.jinja" import retry with context %}


include:
  - kubernetes.helm

kubernetes_cni:
  cmd.run:
    - name: |
        helm upgrade --install cilium cilium/cilium -n {{ kubernetes.cni.config.namespace }} --create-namespace \
        --version {{ kubernetes.cni.config.version }} {{ kubernetes.cni.config.options }}
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
      - sls: kubernetes.helm
