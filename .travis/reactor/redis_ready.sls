redis_orchestrate:
  runner.state.orchestrate:
    - args:
      - mods:
        - redis.server._orchestrate.orchestrate
      - saltenv: {{ salt['environ.get']("SALTENV") }}
      - pillarenv: {{ salt['environ.get']("PILLARENV") }}
      - pillar: {{ data }}

# salt-run state.orchestrate redis.server._orchestrate.orchestrate pillar='{"redis": {"coordinator": "salt-269gf"}}' saltenv=server pillarenv=k8s
# fixme queue the orchestration runs as now they may invoke commands on different minions
