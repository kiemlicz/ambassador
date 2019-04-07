{% from "docker/events/map.jinja" import docker with context %}


include:
  - docker


docker_events:
  file.managed:
    - name: {{ docker.name }}
    - source: {{ docker.source }}
    - user: root
    - group: root
    - mode: 644
    - reload_modules: True
    - require:
      - service: docker
