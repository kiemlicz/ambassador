{%- from "os/lvm/map.jinja" import lvm with context %}

# PV and VG setup only for openEBS purposes for now, to be extended more

{%- for vg, pvs in lvm.vgs.items() %}
{%- for pv in pvs %}
{{ pvname }}:
    lvm.pv_present
      - require_in:
        - lvm: vg_{{ vg }}
{%- endfor %}

vg_{{ vg }}:
  lvm.vg_present:
    - devices: {{ pvs|tojson }}
{%- endfor %}
