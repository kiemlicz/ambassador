start_orchestration:
  runner.state.orchestrate:
    - args:
      - mods:
        - _orchestrate.redis.server.cluster.orch
      - pillar:
          targets: {{ data['minions'] }}
      - saltenv: {{ salt['environ.get']("SALTENV") }}
      - pillarenv: one_user_orch
