{% from "lxc/map.jinja" import lxc with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context -%}

lxc:
  pkg.latest:
    - name: lxc_install
    - pkgs: {{ lxc.pkgs|tojson }}
{{ pkg_latest_opts(attempts=2, interval=30) | indent(4) }}
    - require:
      - sls: os
{%- for config in lxc.config %}
lxc_config_{{ config.name }}:
  file_ext.managed:
    - name: {{ config.name }}
{%- if config.contents is defined %}
    - contents: {{ config.contents | yaml_encode }}
{%- elif config.source is defined %}
    - source: {{ config.source }}
{%- endif %}
    - makedirs: True
    - watch_in:
      - service: {{ lxc.service }}
    - require:
      - pkg: lxc_install
    - require_in:
      - sysctl: net.ipv4.ip_forward
{%- endfor %}
lxc_sysctl:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1
    - config: {{ lxc.sysctl_location }}
    - require:
      - pkg: lxc_install
lxc_service:      
  service.running:
    - name: {{ lxc.service }}
    - enable: True
