{%- from "cert/map.jinja" import cert with context %}

pki_dir:
  file.directory:
  - name: {{ cert.pki_dir }}
  - makedirs: True
  - user: {{ cert.user|default("root") }}
  - group: {{ cert.group|default("root") }}

