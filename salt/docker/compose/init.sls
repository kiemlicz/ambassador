{% from "docker/compose/map.jinja" import docker with context %}
{% from "_macros/dev_tool.macros.jinja" import link_to_bin with context %}

include:
  - docker

docker_compose:
  file.managed:
    - name: {{ docker.compose.location }}
    - source: {{ docker.compose.url }}
    - mode: 755
    - user: {{ docker.compose.owner }}
    - skip_verify: True
    - require:
      - service: {{ docker.service_name }}
docker_compose_link:
{{ link_to_bin(docker.compose.owner_link_location, docker.compose.location, docker.compose.owner) }}
