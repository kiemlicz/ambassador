k8s_orchestrate:
  runner.state.orchestrate:
    - args:
      - mods:
        - _orchestrate.deploy
      - saltenv: {{ salt['environ.get']("SALTENV") }}
