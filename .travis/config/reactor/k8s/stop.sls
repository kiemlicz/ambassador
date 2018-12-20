stop_master_container:
  runner.salt.cmd:
    - args:
      - fun: ps.pkill
      - pattern: supervisord
      - signal: 2
