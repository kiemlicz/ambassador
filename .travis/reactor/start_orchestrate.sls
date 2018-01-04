start_orchestration:
  runner.state.orchestrate:
    - args:
      - mods: _orchestrate.dummy.touch
      - pillar:
          targets: {{ data['minions'] }}
      - saltenv: {{ saltenv }}
