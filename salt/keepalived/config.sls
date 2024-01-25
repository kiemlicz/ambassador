{%- from "keepalived/map.jinja" import keepalived with context %}
{%- for config in keepalived.configs %}
keepalived_config_{{ config.location }}:
  file.managed:
    - name: {{ config.location }}
{%- if config.contents is defined %}
    - contents: {{ config.contents | yaml_encode }}
{%- elif config.source is defined %}
    - source: {{ config.source }}
{%- endif %}
    - makedirs: True
    - template: jinja
    - context:
      keepalived: {{ keepalived|tojson }}
    - watch_in:
      - service: {{ keepalived.service }}
{% endfor %}
