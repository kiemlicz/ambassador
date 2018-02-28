highstate:
  local.state.highstate:
    - tgt: {{ data['minions'] }}
    - tgt_type: list
    - args:
      - saltenv: {{ salt['environ.get']("SALTENV") }}
      - pillarenv: {{ salt['environ.get']("PILLARENV") }}
