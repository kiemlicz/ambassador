{%- from "os/lvm/map.jinja" import lvm with context %}

# PV and VG setup only for openEBS purposes for now, to be extended more

lvm_pkgs:
  pkg.latest:
    - pkgs: {{ lvm.pkgs|tojson }}

{%- for vg, pvs in lvm.vgs.items() %}
{%- set exists = salt['lvm.vgdisplay'](vg) %}
{%- if not exists %}
# skip if exists, otherwise need to constantly adjust /dev/sdX
{%- for pv in pvs %}
{{ pv }}:
    lvm.pv_present:
      - require:
        - pkg: lvm_pkgs
{%- endfor %}

vg_{{ vg }}:
  lvm.vg_present:
    - name: {{ vg }}
    - devices: {{ pvs|tojson }}
{%- endif %}

{%- endfor %}
