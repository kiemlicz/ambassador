{% from "os/network/map.jinja" import network with context %}
{%- for name, interface in network.interfaces.items() %}
{{ name }}:
  network.managed:
{%- for k in interface %}
    - {{ k }}: {{ interface[k]|tojson }}
{%- endfor %}
{%- endfor %}