{% from "samba/map.jinja" import samba with context %}


samba_automount:
  pkg.latest:
    - pkgs: {{ samba.pkgs|tojson }}
    - require:
      - pkg: os_packages
    - require_in:
      - service: {{ samba.service_name }}
  service.running:
    - name: {{ samba.service_name }}
    - enable: True
  file.managed:
    - name: {{ samba.pam_mount_conf }}
    - source: {{ samba.pam_mount_conf_managed }}
    - require:
      - service: {{ samba.service_name }}
#verify if changing the /etc/pam.d/common-session and common-auth is needed