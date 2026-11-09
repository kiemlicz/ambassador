{%- from "kubernetes/fluxcd/map.jinja" import kubernetes with context %}
{% from "_common/util.jinja" import retry, pkg_latest_opts with context %}

include:
    - kubernetes.master

fluxcd_cli:
  cmd.script:
    - name: {{ kubernetes.fluxcd.cli_url }}
    - require:
      - sls: kubernetes.master
{{ retry(attempts=2)| indent(4) }}

fluxcd_bootstrap:
  cmd.run:
    - name: {{ kubernetes.fluxcd.bootstrap }}
    - env: {{ kubernetes.fluxcd.bootstrap_envs|tojson }}
    - require:
      - cmd: fluxcd_cli
{{ retry(attempts=2)| indent(4) }}
# todo add sops secret creation
