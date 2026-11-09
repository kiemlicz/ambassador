{% from "os/mounts/map.jinja" import mounts with context %}
{%- set automounts = [] %}
{% for mount in mounts.list %}
{{ mount.dev }}_mount:
  mount.mounted:
    - name: {{ mount.target }}
    - device: {{ mount.dev }}
    - fstype: {{ mount.file_type }}
    - opts: {{ mount.options }}
    - mkmnt: True
    - persist: True
    - mount: {{ mount.get('mount', True) }}
{%- if 'x-systemd.automount' in mount.options %}
{%- do automounts.append(mount.dev ~ "_mount") %}
{%- endif %}
{% endfor %}

{%- if automounts %}
mounts_systemd_automount_reload:
  cmd.run:
    - name: systemctl daemon-reload && systemctl restart remote-fs.target
    - onchanges:
{%- for id in automounts %}
      - mount: {{ id }}
{%- endfor %}
{%- endif %}

mounts-notification:
  test.succeed_without_changes:
    - name: Mounts setup completed
