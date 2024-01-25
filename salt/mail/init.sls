{%- from "mail/map.jinja" import mail with context -%}

include:
  - os

mail:
  pkg.latest:
    - name: mail_pacakges
    - pkgs: {{ mail.pkgs|tojson }}
    - require:
      - sls: os
{% for name, config in mail.configs.items() if config %}
mail_config_{{ config.location }}:
  file.managed:
    - name: {{ config.location }}
    - source: {{ config.source }}
    - makedirs: True
    - template: jinja
    - user: {{ config.user }}
    - group: {{ config.group }}
    - mode: {{ config.mode }}
    - context:
      settings: {{ config.settings|default({})|tojson }}
    - require:
      - pkg: mail_pacakges
    - watch_in:
      - service: {{ mail.service }}
{% endfor %}
mail_service:
  service.running:
    - name: {{ mail.service }}
    - enable: True
{%- if salt.condition.docker() %}
    - provider: service
{%- endif %}
