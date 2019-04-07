{% from "redis/client/map.jinja" import redis_client as redis with context %}


include:
  - os


redis_client:
  pkg.latest:
    - name: {{ redis.pkg_name }}
    - refresh: True
    - require:
      - sls: os
