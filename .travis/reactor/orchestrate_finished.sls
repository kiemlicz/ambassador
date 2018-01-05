{% if data['fun'] == 'state.sls' %}

# it is impossible to attach reactor for salt/run/*/ret
# because runner is started from reactor
# https://github.com/saltstack/salt/issues/18256
# that's why we check partial jobs corresponding to 'run'

orchestrate_finished:
  runner.guard.check:
    - args:
      - triggering_minion: {{ data['id'] }}
      - expected_minions_list:
        - minion1.local
        - minion2.local
        - minion3.local
      - type: "orchestrate"

{% endif %}
