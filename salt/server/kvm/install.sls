{% from "kvm/map.jinja" import kvm with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}

kvm:
  pkg.latest:
    - name: kvm_packages
    - pkgs: {{ kvm.prerequisites|tojson }}
{{ pkg_latest_opts() | indent(4) }}
    - require:
      - sls: os
  group.present:
    - names: {{ kvm.groups|tojson }}
    - addusers: {{ kvm.users }}
