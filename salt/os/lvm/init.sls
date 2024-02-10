{%- from "os/lvm/map.jinja" import lvm with context %}

# PV and VG setup only for openEBS purposes for now, to be extended more

lvm_pkgs:
  pkg.latest:
    - pkgs: {{ lvm.pkgs|tojson }}

{%- for vg, pvs in lvm.vgs.items() %}
{%- for pv in pvs %}
{{ pv }}:
    lvm.pv_present:
      - require:
        - pkg: lvm_pkgs
      - require_in:
        - lvm: vg_{{ vg }}
{%- endfor %}

vg_{{ vg }}:
  lvm.vg_present:
    - name: {{ vg }}
    - devices: {{ pvs|tojson }}
{%- endfor %}
