{% from "mongodb/server/cluster/map.jinja" import mongodb with context %}


{% set this_host = grains['id'] %}
{% set all_instances = mongodb.replicas + mongodb.shards %}

{% if this_host in all_instances|map(attribute='id')|list %}

include:
  - os
  - mongodb.server.single.install
  - mongodb.server.cluster.configure

{% endif %}
