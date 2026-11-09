{% from "nfs/map.jinja" import nfs with context %}

nfs_server_pkgs:
  pkg.latest:
    - pkgs: {{ nfs.server.pkgs | tojson }}

{%- if nfs.server.config %}
nfs_server_config:
  ini.options_present:
    - name: {{ nfs.server.config_file }}
    - sections: {{ nfs.server.config | tojson }}
    - require:
      - pkg: nfs_server_pkgs
    - watch_in:
      - service: nfs_server_service
{%- endif %}

nfs_server_exports:
  file.managed:
    - name: {{ nfs.server.exports_file }}
    - makedirs: True
    - contents: |
        # Managed by Salt
{%- for export in nfs.server.exports %}
        {{ export.path }} {% for client in export.clients %}{{ client.host }}({{ client.options | join(',') }}) {% endfor %}
{%- endfor %}
    - require:
      - pkg: nfs_server_pkgs

nfs_server_service:
  service.running:
    - name: {{ nfs.server.service }}
    - enable: True
    - require:
      - file: nfs_server_exports

nfs_server_reexport:
  cmd.run:
    - name: exportfs -ra
    - onchanges:
      - file: nfs_server_exports
    - require:
      - service: nfs_server_service