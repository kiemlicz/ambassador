# salt/minion/*/start
virtual_server_init:
  runner.state.orchestrate:
    - args:
      - mods:
        - lvs._orchestrate.virtualservers
      - pillar:
          lvs:
            vs:
              - {{ data['id'] }}
