{%- from "kubernetes/fluxcd/map.jinja" import kubernetes with context %}

include:
    - kubernetes.master

fluxcd_cli:
  cmd.script:
    - name: {{ kubernetes.fluxcd.cli_url }}
    - require:
      - sls: kubernetes.master

fluxcd_bootstrap:
  cmd.run:
    - name: {{ kubernetes.fluxcd.bootstrap }}
    - env: {{ kubernetes.fluxcd.bootstrap_envs|tojson }}
    - require:
      - cmd: fluxcd_cli
