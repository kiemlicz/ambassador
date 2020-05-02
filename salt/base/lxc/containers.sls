{% from "lxc/map.jinja" import lxc with context %}
{% for name, container in lxc.containers.items() %}
lxc_container_{{ name }}:
  lxc.present:
    - name: {{ name }}
    - running: {{ container.running|default(None) }}
    - profile: {{ container.profile|default(None) }}
    - network_profile: {{ container.network_profile|default(None) }}
    - options: {{ container.options|default(None) }}
    - template: {{ container.template|default(None) }}
{% endfor %}

lxc-containers-notification:
  test.show_notification:
  - name: LXC containers setup completed
  - text: "LXC containers setup completed"
