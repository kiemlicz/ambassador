{% from "os/pkgs/map.jinja" import pkgs, pip_provider with context %}

{%- for pkg in pkgs.os_packages %}
verify_os_pkg_{{ pkg }}:
  module_and_function: pkg.upgrade_available
  args:
    - {{ pkg }}
  assertion: assertFalse
{%- endfor %}
