{% from "lxc/map.jinja" import lxc with context %}


{% for name, container in lxc.containers.items() %}
lxc_container_{{ name }}:
  lxc.present:
    - name: {{ name }}
    - running: {{ container.running }}
    - profile: {{ container.profile }}
    - network_profile: {{ container.network_profile }}
{% endfor %}

lxc-containers-notification:
  test.show_notification:
  - name: LXC containers setup completed
  - text: "LXC containers setup completed"
