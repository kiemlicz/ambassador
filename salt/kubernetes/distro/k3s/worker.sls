{%- from "kubernetes/distro/k3s/map.jinja" import k3s with context %}
{%- from "kubernetes/distro/k3s/_install.macros.jinja" import k3s_install with context %}

{%- set masters = k3s.nodes.masters %}
{%- set tokens = salt['mine.get'](masters|first, "kubernetes_token") %}
{%- set envs = k3s.distro_config.env %}
{%- do envs.append({'K3S_TOKEN': tokens[masters|first] | regex_replace('\n','') })%}
# this is file content thus contains new line, which breaks agent join

include:
  - kubernetes.distro.requisites
  - kubernetes.distro.k3s.config

{{ k3s_install(k3s.distro_config.installer_url, envs, k3s.distro_config.args) }}
