{%- from "os/boot/map.jinja" import boot with context %}

{% for file in boot.files %}
{{ file.name }}:
    file.managed:
        - name: {{ file.name }}
        - contents: {{ file.contents }}
{% if 'mode' in file %}
        - mode: {{ file.mode }}
{% endif %}
        - user: {{ file.user|default("root") }}
        - group: {{ file.group|default("root") }}
        - makedirs: True
        - contents_newline: False
{% endfor %}
