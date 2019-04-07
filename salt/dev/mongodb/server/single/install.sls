{% from "mongodb/server/single/map.jinja" import mongodb with context %}
{% from "_common/repo.jinja" import repository with context %}


#mongodb client is installed without adding mongodb repo - thus causes conflicts with official mongo repo
exclude:
  - id: mongodb_client


{% set mongodb_repo_id = "mongodb_repository" %}
{{ repository(mongodb_repo_id, mongodb, enabled=(mongodb.names is defined or mongodb.repo_id is defined),
     require=[{'sls': "os"}], require_in=[{'pkg': mongodb.pkg_name}]) }}
mongodb:
  pkg.latest:
    - name: {{ mongodb.pkg_name }}
    - refresh: True
    - require:
      - sls: os
  file_ext.managed:
    - name: {{ mongodb.config.init_location }}
    - source: {{ mongodb.config.init }}
    - mode: {{ mongodb.config.mode }}
    - template: jinja
    - context:
      mongodb: {{ mongodb|tojson }}
    - require:
      - pkg: {{ mongodb.pkg_name }}
