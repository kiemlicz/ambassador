{% from "influxdb/map.jinja" import influxdb with context %}
{% from "_macros/dev_tool.macros.jinja" import repo_pkg_service with context %}
{% from "_common/util.jinja" import is_docker with context %}


include:
  - os


{{ repo_pkg_service('influxdb', influxdb, not (is_docker()|to_bool)) }}
