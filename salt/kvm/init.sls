{% from "kvm/map.jinja" import kvm with context %}

include:
  - os
  - kvm.install
{%- if kvm.vfio.enabled %}
  - kvm.vfio
{%- endif %}
