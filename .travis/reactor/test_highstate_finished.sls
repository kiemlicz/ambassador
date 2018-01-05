{% if data['fun'] == 'state.highstate' and data['success'] and data['retcode'] == 0 %}

# asserting retcode because: The function "state.highstate" is running as PID ... and was started at ...
# which causes orchestrate to kick in prematurely
# Also this file must contain single entry
# otherwise they get executed in random order even if it is said to be processed in single thread...

highstate_finished:
  runner.wait.until:
    - args:
      - triggering_minion: {{ data['id'] }}
      - expected_minions_list: {{ salt['pillar.get']("minions", pillarenv='one_user_orch') }}
      - action_type: "highstate"

{% endif %}
