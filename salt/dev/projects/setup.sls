{% for username in pillar['users'].keys() %}
{% set user = pillar['users'][username] %}

{% for project in user.projects|default([]) if project.cmds is defined %}

{{ username }}_project_{{ project.url }}_setup:
  cmd.run:
    - names: {{ project.cmds|tojson }}
    - runas: {{ username }}
    - cwd: {{ project.target }}
    - onchanges:
      - git: {{ project.url }}

{% endfor %}

{% for project in user.projects|default([]) if project.configs is defined %}
{% for config in project.configs %}

{{ username }}_project_{{ project.url }}_config_{{ config.name }}:
  file_ext.managed:
    - name: {{ project.target }}/{{ config.name }}
    - source: {{ config.source }}
    - user: {{ username }}
    - makedirs: True
{% if config.context is defined %}
    - context: {{ config.context|tojson }}
{% endif %}
    - onchanges:
      - git: {{ project.url }}

{% endfor %}
{% endfor %}

{% endfor %}
