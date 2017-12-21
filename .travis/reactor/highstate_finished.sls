{% if data['fun'] == 'state.highstate' and data['success'] and data['retcode'] == 0 %}

# asserting retcode because: The function \"state.highstate\" is running as PID ... and was started at ...
# which causes orchestrate to kick in prematurely

{% set jobs = salt['saltutil.runner']("jobs.list_jobs").items()|map(attribute=1)|list %}
{% set completed_minions = jobs|selectattr("Function", "equalto", "state.highstate")|map(attribute='Target')|unique|list %}
{% set expected_minions = ["minion1.local", "minion2.local", "minion3.local"] %}
{# assuming 'state.sls' suffices #}
{% set orch_running_times = jobs|selectattr("Function", "equalto", "state.sls")|list|length %}

{% if completed_minions|compare_lists(expected_minions)|length == 0 and orch_running_times < 1 %}

mark:
  runner.event.send:
    - args:
      - tag: /salt/dummy
      - data:
          test: true

dummy_orchestrate:
  runner.state.orchestrate:
    - args:
      - mods: _orchestrate.dummy.touch
      - pillar:
          targets: {{ completed_minions }}

{% endif %}
{% endif %}
