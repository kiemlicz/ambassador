{% for username in pillar['users'].keys() %}
{% set user = pillar['users'][username] %}

{% for project in user.projects|default([]) %}

{{ username }}_project_clone_{{ project.url }}:
  git.latest:
    - name: {{ project.url }}
    - user: {{ username }}
    - target: {{ project.target }}
{% if project.identity is defined %}
    - identity: {{ project.identity }}
{% endif %}
    - branch: {{ project.branch|default('master') }}
    - require:
      - user: {{ username }}
{% for req in project.requisites|default([]) %}
      - sls: {{ req }}
  file.directory:
    - name: {{ project.target }}
    - user: {{ username }}
    - group: {{ username }}
    - recurse:
      - user
      - group
    - require:
      - git: {{ project.url }}
{% endfor %}


{% endfor %}

{% endfor %}
