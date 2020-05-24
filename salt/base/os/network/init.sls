{% from "os/network/map.jinja" import network with context %}
{%- for name, interface in network.interfaces.items() %}
{{ name }}:
  network.managed:
{%- for k in interface %}
    - {{ k }}: {{ interface[k]|tojson }}
{%- endfor %}
{%- endfor %}

# otherwise state.apply os.network will yield 0 changes which is understood as error in orchestrate
network-notification:
  test.succeed_without_changes:
    - name: Network setup completed
