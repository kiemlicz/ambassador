{% if data['id'] is match('minion\d.local') %}
compose_ready:
  runner.state.orchestrate:
    - args:
        - mods:
            - _orchestrate.highstate
        - saltenv: {{ salt['environ.get']("SALTENV") }}
        - pillarenv: {{ salt['environ.get']("PILLARENV") }}
        - pillar:
            event: {{ data|json_encode_dict }}
{% elif data['id'] is match('salt-\S+') %}
k8s_ready:
    runner.state.orchestrate:
        - args:
            - mods:
                - _orchestrate.start
            - saltenv: {{ salt['environ.get']("SALTENV") }}
            - pillarenv: {{ salt['environ.get']("PILLARENV") }}
            - pillar:
                  docker_event: {{ data|json_encode_dict }}
{% endif %}
