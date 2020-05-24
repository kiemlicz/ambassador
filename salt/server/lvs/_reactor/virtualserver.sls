# salt/minion/*/start
virtual_server_init:
  runner.state.orchestrate:
    - args:
      - mods:
        - lvs._orchestrate.virtualservers
      - saltenv: server
      - pillar:
          lvs:
            vs:
              - {{ data['id'] }}
