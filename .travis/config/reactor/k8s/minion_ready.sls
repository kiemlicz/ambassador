{% if data['id'] is match('salt-minion-\S+') %}
k8s_ready:
    local.state.sls:
        - tgt: {{ data['id'] }}
        - args:
          - mods:
            - minion
          - saltenv: {{ salt['environ.get']("SALTENV") }}
          - pillar:
                docker_event: {{ data|tojson }}
{% endif %}
