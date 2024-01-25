{% from "mongodb/client/map.jinja" import mongodb_client as mongodb with context  %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}

include:
  - os


mongodb_client:
  pkg.latest:
    - name: {{ mongodb.pkg_name }}
{{ pkg_latest_opts() | indent(4) }}
    - require:
      - sls: os
