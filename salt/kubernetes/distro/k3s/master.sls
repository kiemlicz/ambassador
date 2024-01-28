{%- from "kubernetes/distro/k3s/map.jinja" import k3s with context %}
{%- from "kubernetes/distro/k3s/_install.macros.jinja" import k3s_install with context %}

include:
  - kubernetes.distro.requisites
  - kubernetes.distro.k3s.config

{{ k3s_install(k3s.distro_config.installer_url, k3s.distro_config.env) }}

propagate_token:
  module.run:
    - mine.send:
        - kubernetes_token
        - mine_function: file.read
        - {{ k3s.distro_config.token_file }}
    - require:
      - cmd: k3s
