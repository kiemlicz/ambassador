{% from "os/pkgs/map.jinja" import pkgs with context %}

{%- if pkgs.scripts is defined and pkgs.scripts %}
{%- for script in pkgs.scripts %}
pkgs_scripts_{{ script.source }}:
  cmd.script:
    - name: {{ script.source }}
    - args: {{ script.args }}
    - require:
      - sls: os.pkgs
      - sls: os.modules
{% endfor %}
{% endif %}

{%- if pkgs.post_install is defined and pkgs.post_install %}
post_install:
  cmd.run:
    - names: {{ pkgs.post_install|tojson }}
    - onchanges:
      - pkg: os_packages
{% endif %}
