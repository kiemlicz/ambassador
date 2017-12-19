{% if data['id'] in ['minion1.local', 'minion2.local', 'minion3.local'] and data['act'] == "accept" %}

highstate:
  local.state.highstate:
    - tgt: {{ data['id'] }}
    - args:
      - saltenv: base
      - pillarenv: one_user

{% endif %}
