include:
  - os
  - redis.server.install
{% if pillar.get("redis:setup_type", "single") == "single" %}
  - redis.server.configure_single
{% else %}
  - redis.server.configure_cluster
{% endif %}
