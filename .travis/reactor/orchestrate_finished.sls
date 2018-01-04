{% if 'fun' in data and data['fun'] == 'runner.state.orchestrate' %}

# assert result of ret or leave it for scanning
# fixme salt run ret is not matched because all events 'fired by ourselves' are discarded
# this is matched by event user which is present in run/*/ret
# https://github.com/saltstack/salt/issues/18256 local cmd?
# fallback to fun == state.sls from each of minions
# use this fun name as cache's bank name

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

{% endif %}
