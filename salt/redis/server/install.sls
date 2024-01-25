{% from "redis/server/map.jinja" import redis with context %}


redis:
  pkg.latest:
    - name: {{ redis.pkg_name }}
    - require:
      - sls: os
