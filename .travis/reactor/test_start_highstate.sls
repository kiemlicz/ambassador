highstate:
  local.state.highstate:
    - tgt: {{ data['id'] }}
    - args:
      - saltenv: {{ salt['environ.get']("SALTENV") }}
      - pillarenv: {{ salt['environ.get']("PILLARENV") }}
