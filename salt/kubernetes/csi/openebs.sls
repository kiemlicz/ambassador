{% from "kubernetes/csi/map.jinja" import kubernetes with context %}


include:
  - kubernetes.csi.iscsi
  - os.lvm

# openebs is an umbrella:
# LVM sub-chart: https://github.com/openebs/lvm-localpv/tree/develop/deploy/helm/charts
# LVM prereq: https://github.com/openebs/lvm-localpv
kubernetes_csi_openebs_prepare:
  helm.repo_managed:
    - present:
        - name: {{ kubernetes.csi.config.helm.repo }}
          url: {{ kubernetes.csi.config.helm.url }}
{% if 'values' in kubernetes.csi.config.helm %}
  file.managed:
    - name: /tmp/openebs.yaml
    - contents: |
        {{ kubernetes.csi.config.helm.values|indent(8) }}
    - require_in:
      - helm: helm_csi_openebs_release
{%- endif %}

helm_csi_openebs_release:
  helm.release_present:
    - name: {{ kubernetes.csi.config.helm.name }}
    - namespace: {{ kubernetes.csi.config.helm.namespace }}
    - chart: {{kubernetes.csi.config.helm.repo}}/{{kubernetes.csi.config.helm.chart}}
    - version: {{ kubernetes.csi.config.helm.version }}
{%- if 'values' in kubernetes.csi.config.helm %}
    - values: /tmp/openebs.yaml
{%- endif %}
    - flags:
      - "create-namespace"
      - "wait"
    - kvflags:
        kubeconfig: {{ kubernetes.config.locations|join(':') }}
    - require:
      - helm: kubernetes_csi_openebs_prepare
      - sls: kubernetes.csi.iscsi
      - sls: os.lvm
