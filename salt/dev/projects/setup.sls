{% for username in pillar['users'].keys() %}
{% set user = pillar['users'][username] %}

{% for project in user.projects|default([]) if project.cmds is defined %}

{{ username }}_project_{{ project.url }}_setup:
  cmd.run:
    - names: {{ project.cmds|tojson }}
    - runas: {{ username }}
    - cwd: {{ project.target }}
{% if project.shell is defined %}
    - shell: {{ project.shell }}
{% endif %}
    - onchanges:
      - git: {{ project.url }}

{% endfor %}

{% for project in user.projects|default([]) if project.configs is defined %}
{% for config in project.configs %}

{{ username }}_project_{{ project.url }}_config_{{ config.name }}:
  file_ext.managed:
    - name: {{ project.target }}/{{ config.name }}
{% if config.contents is defined %}
    - contents: {{ config.contents | yaml_encode }}
{% else %}
    - source: {{ config.source }}
{% endif %}
    - user: {{ username }}
    - makedirs: True
    - skip_verify: True
{% if config.mode is defined %}
    - mode: {{ config.mode }}
{% endif %}
{% if config.context is defined %}
    - context: {{ config.context|tojson }}
{% endif %}
    - onchanges:
      - git: {{ project.url }}

{% endfor %}
{% endfor %}

{% endfor %}
