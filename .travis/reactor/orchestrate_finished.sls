{% if data['fun'] == 'runner.state.orchestrate' %}
# no runs in jobs.list
# fixme find a way to detect salt-run completion... if this is run so ONE ret should be present but I have multiple
# filter out jobs.listjobs from event log
# state.orchestrate doesn't exist - need to find a way of asserting completed runs
# propagate dedicated event for completion of state.orchestrate, or (if) spawning salt.states - they result in jobs after all
{% set jobs = salt.saltutil.runner("jobs.list_jobs").items()|map(attribute=1)|selectattr("Function", "equalto", "state.orchestrate")|list %}
{% set completed_minions = jobs|map(attribute='Target')|unique|list %}
{% set expected_minions = ["minion1.local", "minion2.local", "minion3.local"] %}

{% if completed_minions|compare_lists(expected_minions)|length == 0 %}

stop_minion_containers:
  local.ps.pkill:
    - tgt: '*'
    - args:
      - pattern: supervisord
      - signal: 2

stop_master_container:
  runner.salt.cmd:
    - args:
      - fun: ps.pkill
      - pattern: supervisord
      - signal: 2

{% endif %}
{% endif %}
