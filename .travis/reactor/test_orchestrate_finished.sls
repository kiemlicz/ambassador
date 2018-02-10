{% if data['fun'] == 'state.sls' %}
# for disabled executions on minions we spawn test.true method
# deliberately not catching this fun == test.true here
# it is required to match on last orchestration run (from mods list)

# note:
# it is impossible to attach reactor for salt/run/*/ret
# because runner is started from reactor
# https://github.com/saltstack/salt/issues/18256
# that's why we check partial jobs corresponding to 'run'

orchestrate_finished:
  runner.wait.until:
    - args:
      - expected_minions_list: {{ salt['pillar.get']("mongodb:replicas", pillarenv='one_user_orch')|selectattr('master')|list }}
      - action_type: "orchestrate"
      - data: {{ data|json }}
      - sls: "mongodb.server.cluster._orchestrate.replicate"

{% elif data['fun'] == 'state.sls' %}

failed:
  runner.event.send:
    - args:
      - tag: 'salt/orchestrate/failure'

{% endif %}
