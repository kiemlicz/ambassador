run_tests:
  runner.state.orchestrate:
    - args:
      - mods:
        - _orchestrate.test
      - saltenv: {{ salt['environ.get']("SALTENV") }}
      - pillar: {{ data }}
