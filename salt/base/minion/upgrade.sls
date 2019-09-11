{% from "minion/map.jinja" import minion with context %}
{% from "_common/util.jinja" import retry with context %}
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

# this state deliberately doesn't use any macros, utils, filter etc so that we're sure that very old minion is able to execute it
minion:
  pkgrepo.managed:
    - name: {{ minion.name }}
    - file: {{ minion.file }}
    - key_url: {{ minion.key_url }}
    - refresh: True
{{ retry()| indent(4) }}
  pkg.latest:
    - name: {{ minion.pkg }}
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
