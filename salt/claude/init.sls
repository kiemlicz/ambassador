{% from "claude/map.jinja" import claude with context %}
{% from "_common/util.jinja" import retry with context %}


include:
  - users


claude:
  cmd.run:
    - name: {{ claude.download_url }}
    - creates: {{ claude.location }}
    {{ retry()| indent(4) }}
    - require:
      - sls: users
