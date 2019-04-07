{% from "mail/map.jinja" import mail with context %}
{% from "_common/util.jinja" import is_docker with context %}


include:
  - os


mail:
  pkg.latest:
    - name: mail_pacakges
    - pkgs: {{ mail.pkgs|tojson }}
    - require:
      - sls: os
{% for config in mail.configs %}
mail_config_{{ config.location }}:
  file_ext.managed:
    - name: {{ config.location }}
    - source: {{ config.source }}
    - makedirs: True
    - template: jinja
    - user: {{ config.user }}
    - group: {{ config.group }}
    - mode: {{ config.mode }}
    - context:
      settings: {{ config.settings|tojson }}
    - require:
      - pkg: mail_pacakges
    - watch_in:
      - service: {{ mail.service }}
{% endfor %}
mail_service:
  service.running:
    - name: {{ mail.service }}
    - enable: True
{% if is_docker() %}
    - provider: service
{% endif %}
