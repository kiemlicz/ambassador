{% from "salt/map.jinja" import salt_installer with context %}
{% from "_macros/dev_tool.macros.jinja" import repo_pkg with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}

include:
  - os
  - salt.repository

{%- for config in salt_installer.ssh.config %}
salt_ssh_{{ config.name }}:
  file_ext.managed:
    - name: {{ config.name }}
    - contents: {{ config.contents | yaml_encode }}
    - template: jinja
    - makedirs: True
    - require_in:
      - pkg: salt_ssh
{%- endfor %}

salt_ssh:
  pkg.latest:
    - name: {{ salt_installer.ssh.pkg_name }}
    - fromrepo: {{ salt_installer.repository.origin|default(None) }}
    - reload_modules: True
{{ pkg_latest_opts() | indent(4) }}
    - require:
      - pkgrepo_ext: salt_repository
