{% from "kannel/map.jinja" import kannel with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}


include:
  - os

kannel_server:
  pkg.latest:
    - name: kannel
    - pkgs: {{ kannel.pkgs|tojson }}
{{ pkg_latest_opts() | indent(4) }}
    - require:
      - sls: os
  service.running:
    - name: {{ kannel.service_name }}
    - enable: True
    - require:
      - pkg: kannel
  file_ext.managed:
    - name: {{ kannel.conf }}
    - source: {{ kannel.conf_source }}
    - context:
      pin: {{ pref.pin }}
      priority : {{ pref.priority }}
    - require:
      - service: {{ kannel.service_name }}
