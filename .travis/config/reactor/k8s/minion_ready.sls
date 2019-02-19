{% if data['id'] is match('minion\d.local') %}
compose_ready:
  runner.state.orchestrate:
    - args:
        - mods:
            - _orchestrate.highstate
        - saltenv: {{ salt['environ.get']("SALTENV") }}
        - pillar:
            event: {{ data|json_encode_dict }}
{% elif data['id'] is match('salt-minion-\S+') %}
k8s_ready:
    local.state.sls:
        - tgt: {{ data['id'] }}
        - args:
            - mods:
                - minion
            - saltenv: {{ salt['environ.get']("SALTENV") }}
            - pillar:
                  docker_event: {{ data|json_encode_dict }}
{% endif %}
