highstate:
  local.state.highstate:
    - tgt: {{ data['id'] }}
    - kwarg:
        saltenv: {{ salt['environ.get']("SALTENV") }}
        pillarenv: one_user_orch
# 2017.7.2
#    - args:
#      - saltenv: {{ salt['environ.get']("SALTENV") }}
#      - pillarenv: one_user_orch
