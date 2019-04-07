redis_orchestrate:
  runner.state.orchestrate:
    - args:
      - mods:
        - redis.server._orchestrate
      - saltenv: server
      - pillarenv: base
