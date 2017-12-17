{% if data['fun'] == 'state.highstate' and data['success'] and data['retcode'] == 0 %}

# asserting retcode because: The function \"state.highstate\" is running as PID ... and was started at ...
# which causes orchestrate to kick in prematurely

{% set jobs = salt['saltutil.runner']("jobs.list_jobs").items()|map(attribute=1)|selectattr("Function", "equalto", "state.highstate")|list %}
{% set completed_minions = jobs|map(attribute='Target')|unique|list %}
{% set expected_minions = ["minion1.local", "minion2.local", "minion3.local"] %}

{% if completed_minions|compare_lists(expected_minions)|length == 0 %}

dummy_orchestrate:
  runner.state.orchestrate:
    - tgt: {{ completed_minions }}
    - tgt_type: list
    - args:
      - mods: _orchestrate.koniec
      - pillar:
          targets: {{ completed_minions }}

{% endif %}
{% endif %}
