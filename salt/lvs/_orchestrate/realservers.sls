{%- set real_servers = salt.saltutil.runner('manage.up', tgt="G@lvs:rs:True", tgt_type="compound") %}

real_servers_network_setup:
  salt.state:
    - tgt: "G@lvs:rs:True"
    - tgt_type: compound
    - sls:
      - os.network
    - saltenv: server

real_servers_network_setup_apply:
  salt.function:
    - tgt: "G@lvs:rs:True"
    - tgt_type: compound
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
    - tgt: "G@lvs:rs:True"
    - tgt_type: compound
    - sls:
      - lxc
      - lvs.realserver
    - saltenv: server
    - require:
      - salt: wait_for_real_servers_setup
