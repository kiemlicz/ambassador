{% from "minion/map.jinja" import minion with context %}

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

#schedule_restart:
#  schedule.present:
#    -
#    - once: ??

# this state deliberately doesn't use any macros, utils, filter etc so that we're sure that very old minion is able to execute it
minion:
  pkgrepo.managed:
    - name: {{ minion.name }}
    - file: {{ minion.file }}
    - key_url: {{ minion.key_url }}
    - refresh: True
  pkg.latest:
    - name: {{ minion.pkg }}
    - order: last
    - require:
      - pkgrepo: minion


#this will break at pkg.latest point since it will replace current minion filesystem with newer version
#it will yield minion unusable till the 'manual' restart, maybe check cron but not the internal salt scheduler that can break with upgrade

minion_service:
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

