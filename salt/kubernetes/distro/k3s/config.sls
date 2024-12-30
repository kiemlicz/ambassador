{%- from "kubernetes/distro/k3s/map.jinja" import k3s with context %}

# rename? move to jinja?

# this is the only place to find options to configure https://github.dev/k3s-io/k3s
# navigate to pkg/daemons/config/types.go
# https://docs.k3s.io/cli/server
k3s_config:
  file.managed:
    - name: {{ k3s.distro_config.installer_file }}
    - contents: {{ k3s.distro_config.installer_config|yaml_encode }}
    - makedirs: True
    - replace: True
    - user: {{ k3s.user }}
    - group: {{ k3s.group|default(k3s.user) }}
    - require:
      - service: docker
