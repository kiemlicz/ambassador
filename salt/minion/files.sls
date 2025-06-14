{% from "minion/map.jinja" import minion with context %}

# e.g. rename interfaces

{% for file in minion.files %}
{{ file.name }}:
    file.managed:
        - name: {{ file.name }}
        - contents: {{ file.contents | yaml_encode }}
{% if 'mode' in file %}
        - mode: {{ file.mode }}
{% endif %}
        - user: {{ file.user|default("root") }}
        - group: {{ file.group|default("root") }}
        - makedirs: True
        - contents_newline: False
{% endfor %}
