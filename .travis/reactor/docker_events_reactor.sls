{% if tag == "salt/engines/docker_events/start"
      and data['data']['Actor']['Attributes']['io.kubernetes.pod.name'] is match('redis-cluster-[\d+]')
      and data['data']['Actor']['Attributes']['io.kubernetes.docker.type'] == "container" %}
  {% if data['data']['status'] == 'start' %}
    redis_instance_started:
      runner.state.orchestrate:
        - args:
          - mods:
            - redis.server._orchestrate.start
          - saltenv: {{ salt['environ.get']("SALTENV") }}
          - pillar:
              docker_event: {{ data|json_encode_dict }}
  {% elif data['data']['status'] == 'stop' or data['data']['status'] == 'kill' %}
    redis_instance_stopped:
      runner.state.orchestrate:
        - args:
          - mods:
            - redis.server._orchestrate.stop
          - saltenv: {{ salt['environ.get']("SALTENV") }}
          - pillar:
              docker_event: {{ data|json_encode_dict }}
  {% endif %}
{% endif %}
