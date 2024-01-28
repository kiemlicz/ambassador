{%- from "kubernetes/distro/k3s/map.jinja" import k3s with context %}

# rename? move to jinja?
k3s_config:
  file.managed:
    - name: {{ k3s.distro_config.installer_file }}
    - contents: {{ k3s.distro_config.installer_config|yaml_encode }}
    - makedirs: True
    - replace: False
    - user: {{ k3s.user }}
    - group: {{ k3s.group|default(k3s.user) }}
    - require:
      - service: docker
