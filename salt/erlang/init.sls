{% from "erlang/map.jinja" import erlang with context %}
{% from "_common/repo.jinja" import preferences with context %}
{% from "_macros/dev_tool.macros.jinja" import repo_pkg with context %}

include:
  - os

{{ preferences("erlang_preferences", erlang, erlang.apt_preferences_source,erlang.apt_preferences_file) }}
    - require_in:
        - pkg: {{ erlang.pkg_name }}
{{ repo_pkg('erlang', erlang) }}
