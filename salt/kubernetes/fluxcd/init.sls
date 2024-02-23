{%- from "kubernetes/fluxcd/map.jinja" import kubernetes with context %}

include:
    - kubernetes.master

fluxcd_cli:
  cmd.script:
    - name: {{ kubernetes.fluxcd.cli_url }}
    - require:
      - sls: kubernetes.master
