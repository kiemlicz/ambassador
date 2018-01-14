start_orchestration:
  runner.state.orchestrate:
    - args:
      - mods:
        - redis.server.cluster._orchestrate.orch
      - pillar:
          targets: {{ data['minions'] }}
      - saltenv: {{ salt['environ.get']("SALTENV") }}
      - pillarenv: one_user_orch

#salt-run state.orchestrate redis.server.cluster._orchestrate.orch pillar='{"targets": ["minion1.local", "minion2.local", "minion3.local"]}' saltenv=dev pillarenv=one_user_orch