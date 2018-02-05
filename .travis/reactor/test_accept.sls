{% if data['id'] in salt['pillar.get']("minions", pillarenv='one_user_orch') and data['act'] == "pend" %}

accept_key:
  wheel.key.accept:
    - kwarg:
        match: {{ data['id'] }}

#from 2017.7.2, use:
#accept_key:
#  wheel.key.accept:
#    - args:
#      - match: {{ data['id'] }}

{% endif %}
