{% from "redis/server/map.jinja" import redis with context %}


redis_config_{{ redis.ip }}_{{ redis.port }}:
  file_ext.managed:
    - name: {{ redis.config.conf_file }}
    - source: {{ redis.config.source }}
    - makedirs: True
    - template: jinja
    - context:
      redis: {{ redis|tojson }}
    - require:
      - pkg: {{ redis.pkg_name }}
  service.running:
    - name: {{ redis.config.service }}
    - enable: True
    - watch:
      - file_ext: {{ redis.config.conf_file }}
