{% from "os/mounts/map.jinja" import mounts with context %}


{% for mount in mounts.list %}
{{ mount.dev }}_mount:
  mount.mounted:
    - name: {{ mount.target }}
    - device: {{ mount.dev }}
    - fstype: {{ mount.file_type }}
    - opts: {{ mount.options }}
    - mkmnt: True
    - persist: True
{% endfor %}

mounts-notification:
  test.show_notification:
    - name: Mounts setup completed
    - text: "Mounts setup completed"
