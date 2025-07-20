{% from "os/sysctl/map.jinja" import sysctls with context %}

{%- for k,v in sysctls.items() %}
sysctl_{{ k }}:
  sysctl.present:
    - name: {{ k }}
    - value: {{ v }}
    - require:
      - sls: os.pkgs
{%- endfor %}
