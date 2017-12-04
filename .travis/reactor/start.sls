highstate:
  local.state.highstate:
    - tgt: *
    - args:
      - saltenv: dev
