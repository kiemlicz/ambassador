redis_orchestrate:
  runner.state.orchestrate:
    - args:
      - mods:
        - redis.server._orchestrate.orchestrate
      - saltenv: {{ salt['environ.get']("SALTENV") }}
      - pillarenv: {{ salt['environ.get']("PILLARENV") }}
