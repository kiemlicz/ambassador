{% from "minion/map.jinja" import minion with context %}
{%- if grains['os'] != 'Windows' %}
minion_restart:
  cmd.run:
    - name: "salt-call service.restart {{ minion.service }}"
    - bg: True
    - onchanges:
      - pkg: minion
{%- endif %}
