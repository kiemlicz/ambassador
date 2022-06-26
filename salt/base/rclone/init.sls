{% from "rclone/map.jinja" import rclone with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context -%}

include:
  - os
  - users

rclone:
  pkg.latest:
    - name: rclone_install
    - pkgs: {{ rclone.pkgs|tojson }}
{{ pkg_latest_opts(attempts=2, interval=30) | indent(4) }}
    - require:
      - sls: os
      - sls: users

fuse_config:
  file.append:
    - name: {{ rclone.fuse_config }}
    - text: {{ rclone.fuse_config_append }}
    - require:
      - pkg: rclone_install

{% for config in rclone.configs if rclone.configs %}
rclone_config_{{ config.name }}:
  file.managed:
    - name: {{ config.name }}
{%- if config.contents is defined %}
    - contents: {{ config.contents | yaml_encode }}
{%- elif config.source is defined %}
    - source: {{ config.source }}
{%- endif %}
    - makedirs: True
    - user: {{ config.user | default("root") }}
    - group: {{ config.group | default("root") }}
    - require:
      - pkg: rclone_install
{% if config.service_name is defined %}
    - require_in:
      - service: {{ config.service_name }}
{% endif %}

{% if config.service_name is defined %}
{{ config.service_name }}:
  service.running:
    - name: {{ config.service_name }}
    - enable: True
    - require:
      - file: {{ rclone.fuse_config }}
{% endif %}

{%- endfor %}
