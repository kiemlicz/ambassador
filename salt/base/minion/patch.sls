{%- from "minion/map.jinja" import minion with context %}
# for patching files which cannot be overriden using standard `_type` overrides, like salt/templates/
{%- for f in minion.patch.files %}
{{ f.name }}:
 file.managed:
    - source: {{ f.source }}
{%- endfor %}
