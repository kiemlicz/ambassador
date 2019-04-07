{% from "mongodb/server/cluster/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_configure with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}
{% set all_instances = mongodb.replicas + mongodb.shards %}
{% for bind in all_instances|selectattr("id", "equalto", this_host)|list %}
{% set discriminator = mongodb.config.service + '-' + bind.port|string %}
{% do bind.update({
  "ip": bind.ip|default(ip())
}) %}
{{ mongodb_configure(mongodb, bind, discriminator) }}

{% endfor %}
