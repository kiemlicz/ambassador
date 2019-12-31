{% from "samba/map.jinja" import samba with context %}


samba_automount:
  pkg.latest:
    - pkgs: {{ samba.pkgs|tojson }}
    - require:
      - pkg: os_packages
    - require_in:
      - service: {{ samba.service_name }}
  file.managed:
    - name: {{ samba.pam_mount_conf }}
    - source: {{ samba.pam_mount_conf_managed }}
    - require:
      - pkg: samba_automount
  service.running:
    - name: {{ samba.service_name }}
    - enable: True
    - watch:
      - file: {{ samba.pam_mount_conf }}

#verify if changing the /etc/pam.d/common-session and common-auth is needed