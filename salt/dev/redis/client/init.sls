{% from "redis/client/map.jinja" import redis_client as redis with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}

include:
  - os


redis_client:
  pkg.latest:
    - name: {{ redis.pkg_name }}
{{ pkg_latest_opts() | indent(4) }}
    - require:
      - sls: os
