stop_minion_containers:
  local.ps.pkill:
    - tgt: '*'
    - args:
      - pattern: supervisord
      - signal: 2

stop_master_container:
  runner.salt.cmd:
    - args:
      - fun: ps.pkill
      - pattern: supervisord
      - signal: 2
