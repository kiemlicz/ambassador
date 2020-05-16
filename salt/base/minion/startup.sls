{% from "minion/map.jinja" import minion with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}

minion_required_pip3_provider:
  pkg.latest:
    - name: python3-pip
    - reload_modules: True
{{ pkg_latest_opts(attempts=4, interval=30) | indent(4) }}

minion_required_pip3_packages:
  pip.installed:
    - name: startup_pip3_packages
    - pkgs: {{ minion.startup.pip3|tojson }}
    - bin_env: '/usr/bin/pip3'
    - reload_modules: True
    - require:
      - pkg: python3-pip
