{%- from "kubernetes/kubevirt/map.jinja" import kubernetes with context %}
{%- from "_common/util.jinja" import retry with context %}

include:
    - kubernetes.master

kubevirt_operator_apply:
  cmd.run:
    - name: kubectl apply -f {{ kubernetes.kubevirt.operator }}
    - env:
      - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    {{ retry(attempts=3)| indent(4) }}
    - require:
      - sls: kubernetes.master
kubevirt_cr_apply:
  cmd.run:
    - name: kubectl apply -f {{ kubernetes.kubevirt.cr }}
    - env:
      - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    {{ retry(attempts=3)| indent(4) }}
    - require:
      - cmd: kubevirt_operator_apply
