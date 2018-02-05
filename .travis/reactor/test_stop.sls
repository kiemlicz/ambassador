stop_minion_containers:
  local.ps.pkill:
    - tgt: '*'
    - kwarg:
        pattern: supervisord
        signal: 2
# 2017.7.2
#    - args:
#      - pattern: supervisord
#      - signal: 2

stop_master_container:
  runner.salt.cmd:
    - arg:
      - ps.pkill
    - kwarg:
        pattern: supervisord
        signal: 2
# 2017.7.2
#    - args:
#      - fun: ps.pkill
#      - pattern: supervisord
#      - signal: 2
