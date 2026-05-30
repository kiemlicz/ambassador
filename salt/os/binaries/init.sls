{%- from "os/binaries/map.jinja" import binaries with context %}

# handles self-contained binaries hosted either as raw binary or archived
# differs from devtool which downloads not self-contained archives

{% set archives = binaries.archives %}
{% set files = binaries.files %}

{%- for archive in archives %}
extract_{{ archive.name }}:
  # todo add support to rename file if archived with different name
  archive.extracted:
    - name: {{ binaries.location }}
    - source: {{ archive.link }}
    - skip_verify: True
    - enforce_toplevel: False
    - require:
        - sls: os.pkgs
  file.managed:
    - name: {{ binaries.location }}/{{ archive.name }}
    - mode: 0755
    - require:
        - archive: extract_{{ archive.name }}
{%- endfor %}

{%- for f in files %}
download_bin_{{ f.name }}:
  file.managed:
    - name: {{ binaries.location }}/{{ f.name }}
    - source: {{ f.link }}
    - skip_verify: True
    - mode: 0755
    - require:
        - sls: os.pkgs
{%- endfor %}
