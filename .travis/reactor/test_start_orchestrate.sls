start_orchestration:
  runner.state.orchestrate:
    - args:
      - mods:
        - _orchestrate.redis.server.cluster.orch
      - pillar:
          targets: {{ data['minions'] }}
      - saltenv: {{ salt['environ.get']("SALTENV") }}
      - pillarenv: one_user_orch

#salt-run state.orchestrate _orchestrate.redis.server.cluster.orch pillar='{"targets": ["minion1.local", "minion2.local", "minion3.local"]}' saltenv=dev pillarenv=one_user_orch