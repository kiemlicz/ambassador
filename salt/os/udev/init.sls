{%- from "os/udev/map.jinja" import udev with context %}

{%- for rule in udev.rules %}
{{ rule.name }}:
    file.managed:
        - name: {{ rule.name }}
        - contents: {{ rule.contents | yaml_encode }}
{% if 'mode' in rule %}
        - mode: {{ rule.mode }}
{% endif %}
        - user: {{ rule.user|default("root") }}
        - group: {{ rule.group|default("root") }}
        - makedirs: True
{%- endfor %}
