# if enumerating orchestrators in mods won't be sufficient then create root orchestrator
# with clean requisite statements etc.

start_orchestration:
  runner.state.orchestrate:
    - args:
      - mods:
        - redis.server.cluster._orchestrate.orch
        - mongodb.server.cluster._orchestrate.orch
      - saltenv: {{ saltenv }}
