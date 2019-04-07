{% from "keepalived/map.jinja" import keepalived with context %}


{% for config in keepalived.configs.values() %}

keepalived_config_{{ config.location }}:
  file_ext.managed:
    - name: {{ config.location }}
    - source: {{ config.source }}
    - makedirs: True
    - template: jinja
    - context:
      keepalived: {{ keepalived|tojson }}
    - watch_in:
      - service: {{ keepalived.service }}

{% endfor %}
