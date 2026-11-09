{% from "zfs/map.jinja" import zfs with context %}

include:
  - zfs

sanoid_pkgs:
  pkg.latest:
    - pkgs: {{ zfs.sanoid.pkgs | tojson }}
    - require:
      - test: zfs-notification

sanoid_config:
  file.managed:
    - name: {{ zfs.sanoid.config }}
    - source: salt://zfs/sanoid.conf
    - template: jinja
    - makedirs: True
    - context:
        templates: {{ zfs.sanoid.templates | tojson }}
        datasets: {{ zfs.sanoid.datasets | tojson }}
    - require:
      - pkg: sanoid_pkgs

sanoid_timer:
  service.running:
    - name: {{ zfs.sanoid.timer }}
    - enable: True
    - require:
      - file: sanoid_config