{%- from "kubernetes/cni/map.jinja" import kubernetes with context %}
{%- from "_common/util.jinja" import retry with context %}


include:
  - kubernetes.helm

kubernetes_cni_repo:
  helm.repo_managed:
    - present:
        - name: {{ kubernetes.cni.config.helm.repo }}
          url: https://helm.cilium.io/
kubernetes_cni_release:
  helm.release_present:
    - name: {{ kubernetes.cni.config.helm.name }}
    - namespace: {{ kubernetes.cni.config.helm.namespace }}
    - chart: {{kubernetes.cni.config.helm.repo}}/{{kubernetes.cni.config.helm.chart}}
    - version: {{ kubernetes.cni.config.helm.version }}
    - set: {{ kubernetes.cni.config.helm.set|tojson }}
    - flags:
      - "create-namespace"
      - "wait"
    - kvflags:
        kubeconfig: {{ kubernetes.config.locations|join(':') }}
    - require:
      - helm: kubernetes_cni_repo
      - sls: kubernetes.helm
