{% from "redis/server/map.jinja" import redis with context %}
{% from "redis/server/macros.jinja" import redis_configure with context %}
{% from "_common/ip.jinja" import ip with context %}


redis_init_script:
  file_ext.managed:
    - name: {{ redis.config.init_location }}
    - source: {{ redis.config.init }}
    - mode: {{ redis.config.mode }}
    - template: jinja
    - context:
      redis: {{ redis|tojson }}
    - require:
      - pkg: {{ redis.pkg_name }}

{% set this_host = grains['id'] %}
{% set all_instances = redis.masters + redis.slaves %}
{% for bind in all_instances|selectattr("name", "equalto", this_host)|list %}

{% set instance_number = bind.port|string %}
{% do bind.update({
  "ip": bind.ip|default(ip())
}) %}

{% if salt['grains.get']("init") == 'systemd' %}

{% set service = redis.config.service ~ '@' ~ bind.port|string %}
{{ redis_configure(redis, ip=bind.ip, port=bind.port, instance_number=instance_number, service=service) }}

{% else %}

{% set service = redis.config.service ~ '-' ~ instance_number %}
{{ redis_configure(redis, ip=bind.ip, port=bind.port, instance_number=instance_number, service=service) }}

{% endif %}

{% endfor %}
