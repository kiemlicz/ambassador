{% from "salt/map.jinja" import salt_installer with context %}
{% from "_macros/dev_tool.macros.jinja" import repo_pkg with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}
{% from "_common/util.jinja" import retry with context %}

include:
  - os
  - salt.repository

{%- for config in salt_installer.master.config|selectattr("initial", "equalto", True)|list %}
salt_master_{{ config.name }}:
  file.managed:
    - name: {{ config.name }}
    - contents: {{ config.contents | yaml_encode }}
    - template: jinja
    - user: {{ config.user | default("root") }}
    - group: {{ config.group | default("root") }}
    - mode: {{ config.mode | default(644) }}
    - makedirs: True
    - require_in:
      - pkg: salt_master
{%- endfor %}

salt_master:
  pkg.latest:
    - name: {{ salt_installer.master.pkg_name }}
    - fromrepo: {{ salt_installer.repository.origin|default(None) }}
    - reload_modules: True
{{ pkg_latest_opts() | indent(4) }}
    - require:
      - pkgrepo_ext: salt_repository
  service.running:
    - name: {{ salt_installer.master.service }}
    - init_delay: {{ salt_installer.master.service_init_delay }}
    - require:
      - pkg: salt_master

salt_master_sync_modules:
  cmd.run:
    - name: {{ salt_installer.master.sync_cmd }}
{{ retry(attempts=3, interval=30)| indent(4) }}
    - require:
      - service: salt_master

{%- for config in salt_installer.master.config|selectattr("initial", "equalto", False)|list %}
salt_master_{{ config.name }}:
  file.managed:
    - name: {{ config.name }}
    - contents: {{ config.contents | yaml_encode }}
    - template: jinja
    - makedirs: True
    - require:
      - service: salt_master
    - require_in:
      - service: salt_master_apply_extra_config
# deliberately not adding watch_in salt-master service as this would make this state run before initial service start
{%- endfor %}

{%- if salt_installer.master.config|selectattr("initial", "equalto", False)|list %}
#the reason of second restart: to allow use of custom sdb modules in config files
#custom sdb modules cannot be present during first service start, since they will break the Salt
salt_master_apply_extra_config:
  service.mod_watch:
    - name: {{ salt_installer.master.service }}
    - sfun: running
    - full_restart: True
{%- endif %}
