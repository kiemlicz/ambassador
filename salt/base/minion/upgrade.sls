{% from "minion/map.jinja" import minion with context %}
{% from "_common/repo.jinja" import repository with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}

{%- if grains['os_family'] == 'Debian' %}

disable_service_start:
  file.managed:
    - name: /usr/sbin/policy-rc.d
    - user: root
    - group: root
    - mode: 0755
    - contents:
      - '#!/bin/sh'
      - exit 101
    # do not touch if already exists
    - replace: False
    - prereq:
      - pkg: minion

{%- endif %}

{{ repository("salt_repository", minion) }}
minion:
  pkg.latest:
    - pkgs: {{ minion.pkgs|tojson }}
    - order: last
{{ pkg_latest_opts(attempts=3) | indent(4) }}

minion_enable:
  service.enabled:
    - name: {{ minion.service }}
    - require:
      - pkg: minion

{%- if grains['os_family'] == 'Debian' %}

enable_service_start:
  file.absent:
    - name: /usr/sbin/policy-rc.d
    - onchanges:
      - pkg: minion

{%- endif %}

{%- if grains['os'] != 'Windows' %}
minion_restart:
  cmd.run:
    - name: "salt-call service.restart {{ minion.service }}"
    - bg: True
    - onchanges:
      - pkg: minion
{%- endif %}
