accept_key:
  wheel.key.accept:
    - args:
      - match: {{ data['id'] }}

highstate:
  local.state.highstate:
    - tgt: {{ data['id'] }}
    - args:
      - saltenv: base
      # take SALTENV arg here
