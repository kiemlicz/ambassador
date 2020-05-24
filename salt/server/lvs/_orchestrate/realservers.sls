{%- set real_servers = salt.pillar.get("lvs:rs", []) %}
real_servers_network_setup:
  salt.state:
    - tgt: {{ real_servers|join(",") }}
    - tgt_type: list
    - sls:
      - os.network
    - saltenv: server

real_servers_network_setup_apply:
  salt.function:
    - tgt: {{ real_servers|join(",") }}
    - tgt_type: list
    - name: system.reboot
    - onchanges:
      - salt: real_servers_network_setup

wait_for_real_servers_setup:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: {{ real_servers|tojson }}
    - onchanges:
      - salt: real_servers_network_setup_apply

real_servers_setup:
  salt.state:
    - tgt: {{ real_servers|join(",") }}
    - tgt_type: list
    - highstate: True
    - saltenv: server
    - require:
      - salt: wait_for_real_servers_setup
