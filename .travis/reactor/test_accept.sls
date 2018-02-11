{% if data['id'] in salt['pillar.get']("minions", pillarenv=salt['environ.get']("PILLARENV")) and data['act'] == "pend" %}

#pre 2017.7.2, use (in all reactor sls'es):
#accept_key:
#  wheel.key.accept:
#    - kwarg:
#        match: {{ data['id'] }}
accept_key:
  wheel.key.accept:
    - args:
      - match: {{ data['id'] }}

{% endif %}
