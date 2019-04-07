{% from "erlang/map.jinja" import erlang with context %}
{% from "_common/util.jinja" import retry with context %}
{% from "_common/repo.jinja" import repository, preferences with context %}


include:
  - os


{% set erlang_repo_id = "erlang_repository" %}

{{ repository(erlang_repo_id, erlang, enabled=(erlang.names is defined or erlang.repo_id is defined), require=[{'sls': "os"}]) }}
{% if erlang.names is defined %}
{{ preferences("erlang_preferences", erlang, erlang.apt_preferences_source,erlang.apt_preferences_file) }}
    - require:
      - pkgrepo_ext: {{ erlang_repo_id }}
    - require_in:
        - pkg: {{ erlang.pkg_name }}
{% endif %}
erlang:
  pkg.latest:
    - name: {{ erlang.pkg_name }}
    - refresh: True
    - require:
      - pkgrepo_ext: {{ erlang_repo_id }}
