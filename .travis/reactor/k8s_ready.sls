k8s_ready:
    runner.state.orchestrate:
        - args:
            - mods:
                - _orchestrate.deploy
            - saltenv: server
            - pillarenv: base
            - pillar:
                  docker_event: {{ data|json_encode_dict }}
