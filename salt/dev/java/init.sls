{% from "java/map.jinja" import default_java as java with context %}
{% from "java/map.jinja" import version_major with context %}
{% from "_macros/dev_tool.macros.jinja" import add_environmental_variable,add_to_path with context %}
{% from "_common/util.jinja" import retry with context %}
{% from "_common/repo.jinja" import repository with context %}


include:
  - os


{% set java_repo_id = "java_repository" %}
{{ repository(java_repo_id, java, enabled=(java.names is defined or java.repo_id is defined),
   require=[{'sls': "os"}]) }}
java:
{% if java.names is defined %}
  debconf.set:
    - name: {{ java.pkg_name }}
    - data:
  {% if version_major == "11" %}
        'shared/accepted-oracle-license-v1-2': {'type': 'boolean', 'value': True}
  {% else %}
        'shared/accepted-oracle-license-v1-1': {'type': 'boolean', 'value': True}
  {% endif %}
    - require:
      - pkgrepo_ext: {{ java_repo_id }}
    - require_in:
      - pkg: {{ java.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ java.pkg_name }}
    - pkgs: {{ ([ java.pkg_name ] + java.ext_pkgs)|tojson }}
    - refresh: True
{{ retry(attempts=3)| indent(4) }}
    - require:
      - sls: os
      - pkgrepo_ext: {{ java_repo_id }}
{{ add_environmental_variable(java.environ_variable, java.generic_link, java.exports_file) }}
{{ add_to_path(java.environ_variable, java.path_inside, java.exports_file) }}

#todo windows: like sbt - detect dir for JAVA_HOME