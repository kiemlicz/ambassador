{% if data['id'] is match('minion\d.local') %}
compose_ready:
  runner.state.orchestrate:
    - args:
        - mods:
            - _orchestrate.highstate
        - saltenv: {{ salt['environ.get']("SALTENV") }}
        - pillar:
            event: {{ data|tojson }}
{% elif data['id'] is match('salt-\S+') %}
k8s_ready:
    runner.state.orchestrate:
        - args:
            - mods:
                - _orchestrate.start
            - saltenv: {{ salt['environ.get']("SALTENV") }}
            - pillar:
                  docker_event: {{ data|tojson }}
{% endif %}
