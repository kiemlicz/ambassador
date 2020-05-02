{%- from "lxc/map.jinja" import lxc with context %}
{%- for container in lxc.containers.items() %}
# fixme run on VM
verify_lxc_{{ container.name }}:
  module_and_function: lxc.exists
  args:
    - {{ container.name }}
  assertion: assertTrue
{%- endfor %}
