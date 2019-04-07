{% from "virtualbox/map.jinja" import virtualbox with context %}
{% from "_common/repo.jinja" import repository with context %}


include:
  - os


{% set virtualbox_repo_id = "virtualbox_repository" %}
{{ repository(virtualbox_repo_id, virtualbox, enabled=(virtualbox.names is defined or virtualbox.repo_id is defined),
     require=[{'sls': "os"}], require_in=[{'pkg': virtualbox.pkg_name}]) }}
virtualbox:
  pkg.latest:
    - name: {{ virtualbox.pkg_name }}
    - refresh: True
    - require:
      - sls: os
