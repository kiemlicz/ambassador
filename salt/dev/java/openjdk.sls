{% from "java/map.jinja" import openjdk_java as java with context %}
{% from "_macros/dev_tool.macros.jinja" import add_environmental_variable,add_to_path with context %}
{% from "_common/util.jinja" import pkg_latest_opts  with context %}


include:
  - os


# since openjdk may require setup of backports-type repo, setup it using os.repositories state (along with preferences)
java:
  pkg.latest:
    - name: {{ java.pkg_name }}
    - pkgs: {{ ([ java.pkg_name ] + java.ext_pkgs)|tojson }}
{{ pkg_latest_opts(attempts=3) | indent(4) }}
    - require:
      - sls: os
{{ add_environmental_variable(java.environ_variable, java.generic_link, java.exports_file) }}
{{ add_to_path(java.environ_variable, java.path_inside, java.exports_file) }}
