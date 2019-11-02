{% from "salt/map.jinja" import salt_installer with context %}
{% from "_macros/dev_tool.macros.jinja" import repo_pkg with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}

include:
  - os
  - salt.repository

{%- for config in salt_installer.api.config %}
salt_api_{{ config.name }}:
  file_ext.managed:
    - name: {{ config.name }}
    - contents: {{ config.contents | yaml_encode }}
    - template: jinja
    - makedirs: True
    - require_in:
      - pkg: salt_api
{%- endfor %}

salt_api:
  pkg.latest:
    - name: {{ salt_installer.api.pkg_name }}
{{ pkg_latest_opts() | indent(4) }}
    - require:
      - pkgrepo_ext: salt_repository
