{% if data['fun'] == 'state.highstate' %}
{% set highstates = salt.saltutil.runner("jobs.list_jobs").items()|map(attribute=1)|selectattr("Function", "equalto", "state.highstate")|list %}
{% if highstates|length >= 3 %}

finished:
  runner.salt.cmd:
    - args:
      - fun: file.touch
      - name: /tmp/hs_stop_{{ data['jid'] }}

{% endif %}
{% endif %}
