{%- from "docker/map.jinja" import docker with context %}
{%- from "_macros/dev_tool.macros.jinja" import repo_pkg_service with context -%}

include:
  - os

{{ repo_pkg_service('docker', docker, not salt.condition.docker()) }}
