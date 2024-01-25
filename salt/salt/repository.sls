{% from "salt/map.jinja" import salt_installer with context %}
{% from "_common/repo.jinja" import repository, preferences with context %}

include:
  - os

{{ repository("salt_repository", salt_installer.repository, require=[{'sls': "os"}]) }}
