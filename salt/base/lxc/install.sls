{% from "lxc/map.jinja" import lxc with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}


lxc:
  pkg.latest:
    - name: lxc_install
    - pkgs: {{ lxc.pkgs|tojson }}
{{ pkg_latest_opts() | indent(4) }}
    - require:
      - sls: os
  file.managed:
    - name: {{ lxc.config.net_file }}
    - source: {{ lxc.config.net_source }}
    - makedirs: True
    - require:
      - pkg: lxc_install
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1
    - config: {{ lxc.config.sysctl_location }}
    - require:
      - file: {{ lxc.config.net_file }}
  service.running:
    - name: {{ lxc.service }}
    - enable: True
    - watch:
      - file: {{ lxc.config.net_file }}
