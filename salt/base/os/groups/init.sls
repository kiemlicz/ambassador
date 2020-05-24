{% from "os/groups/map.jinja" import groups with context %}

{%- for group in groups.present %}
{{ group.name }}_present:
  group.present:
    - name: {{ group.name }}
    - system: {{ group.system|default(False) }}
{%- if group.gid is defined %}
    - gid: {{ group.gid }}
{%- endif %}
{%- if group.addusers is defined %}
    - addusers: {{ group.addusers }}
{%- endif %}
{%- if group.delusers is defined %}
    - delusers: {{ group.delusers }}
{%- endif %}
{%- if group.members is defined %}
    - members: {{ group.members }}
{%- endif %}
{%- endfor %}

groups-notification:
  test.succeed_without_changes:
    - name: Gropus setup completed
