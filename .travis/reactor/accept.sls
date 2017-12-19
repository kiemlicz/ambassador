{% if data['id'] in ['minion1.local', 'minion2.local', 'minion3.local'] and data['act'] == "pend" %}

accept_key:
  wheel.key.accept:
    - args:
      - match: {{ data['id'] }}

{% endif %}
