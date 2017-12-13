{% if data['fun'] == 'state.orchestrate' %}
{% set jobs = salt.saltutil.runner("jobs.list_jobs").items()|map(attribute=1)|selectattr("Function", "equalto", "state.highstate")|list %}
{% set completed_minions = jobs|map(attribute='Target')|unique %}
{% if completed_minions|length >= 3 %}

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
