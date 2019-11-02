{% from "salt/map.jinja" import salt_installer with context %}
{% from "_macros/dev_tool.macros.jinja" import repo_pkg with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}

include:
  - os
  - salt.repository

{%- for config in salt_installer.master.config %}
salt_master_{{ config.name }}:
  file_ext.managed:
    - name: {{ config.name }}
    - contents: {{ config.contents | yaml_encode }}
    - template: jinja
    - makedirs: True
    - require_in:
      - pkg: salt_master
{%- endfor %}

salt_master:
  pkg.latest:
    - name: {{ salt_installer.master.pkg_name }}
{{ pkg_latest_opts() | indent(4) }}
    - require:
      - pkgrepo_ext: salt_repository

salt_autosign:
  file.managed:
    - name: {{ salt_installer.master.autosign.file }}
    - contents: {{ salt_installer.master.autosign.contents|default("") }}
    - user: {{ salt_installer.master.autosign.user|default("root") }}
    - group: {{ salt_installer.master.autosign.group|default("root") }}
{%- if salt_installer.master.autosign.mode is defined %}
    - mode: {{ salt_installer.master.autosign.mode }}
{%- endif %}
    - makedirs: True
    - require:
      - pkg: salt_master
