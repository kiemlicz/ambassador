{% set pillarenv = salt['environ.get']("PILLARENV") %}
{% if data['id'] in salt['pillar.get']("minions", pillarenv=pillarenv) and data['act'] == "pend" %}

#fixme - there is no data, pass via pillar in reaction

accept_minion_key:
  salt.wheel:
    - name: key.accept
    - match: {{ data['id'] }}

{% endif %}
