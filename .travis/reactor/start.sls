highstate:
  local.state.highstate:
    - tgt: {{ data['id'] }}
    - args:
      - saltenv: base
      - pillarenv: one_user
