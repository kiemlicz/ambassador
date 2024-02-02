{%- from "kubernetes/cni/map.jinja" import kubernetes with context %}
{%- from "_common/util.jinja" import retry with context %}


include:
  - kubernetes.helm

kubernetes_cni:
  cmd.run:
    - name: |
        helm upgrade --install {{ kubernetes.cni.config.release_name }} cilium/cilium -n {{ kubernetes.cni.config.release_namespace }} --create-namespace \
        --version {{ kubernetes.cni.config.version }} {{ kubernetes.cni.config.options }}
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
      - sls: kubernetes.helm
