{% if data['fun'] == 'state.sls' %}

# it is impossible to attach reactor for salt/run/*/ret
# because runner is started from reactor
# https://github.com/saltstack/salt/issues/18256
# that's why we check partial jobs corresponding to 'run'

orchestrate_finished:
  runner.wait.until:
    - args:
      - triggering_minion: {{ data['id'] }}
      - expected_minions_list: {{ salt['pillar.get']("minions", pillarenv='one_user_orch') }}
      - action_type: "orchestrate"

{% endif %}
