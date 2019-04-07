{% from "mongodb/server/single/map.jinja" import mongodb with context %}
{% from "_common/ip.jinja" import ip with context %}
{% from "_common/util.jinja" import is_docker with context %}


{% set discriminator = mongodb.config.service %}
{% set bind = {
  'port': mongodb.port,
  'ip': mongodb.ip|default(ip())
} %}
mongodb_init:
  file_ext.managed:
    - name: {{ mongodb.config.init_location }}
    - source: {{ mongodb.config.init }}
    - mode: {{ mongodb.config.mode }}
    - template: jinja
    - context:
      mongodb: {{ mongodb|tojson }}
      discriminator: {{ discriminator }}
    - require:
      - pkg: {{ mongodb.pkg_name }}
mongodb_config:
  file_ext.managed:
    - name: /etc/{{ mongodb.config.service }}.conf
    - source: {{ mongodb.config.source }}
    - makedirs: True
    - template: jinja
    - context:
      bind: {{ bind|tojson }}
      mongodb: {{ mongodb|tojson }}
      discriminator: {{ discriminator }}
    - require:
      - file_ext: {{ mongodb.config.init_location }}
  file.directory:
    - names:
      - {{ mongodb.config.db_path }}/{{ discriminator }}
      - {{ mongodb.config.pid_path }}
      - {{ mongodb.config.log_path }}
    - user: {{ mongodb.user }}
    - group: {{ mongodb.group }}
    - makedirs: True
    - require:
      - file_ext: /etc/{{ mongodb.config.service }}.conf
    - require_in:
      - service: {{ mongodb.config.service }}
  service.running:
    - name: {{ mongodb.config.service }}
{% if not is_docker() %}
    - enable: True
{% endif %}
