{% set masters = salt.saltutil.runner('manage.up', tgt="k3sm*") %}
{% set workers = salt.saltutil.runner('manage.up', tgt="k3sw*") %}
{% set allnodes = [] %}
{% do allnodes.extend(masters) %}
{% do allnodes.extend(workers) %}

sync_modules_master:
  salt.runner:
  - name: saltutil.sync_all

sync_minions:
  salt.function:
  - tgt: "k3s*"
  - name: saltutil.sync_all
  - kwarg:
        refresh: True

#setup_prerequisites:
#  salt.state:
#  - tgt: "k3s*"
#  - sls:
#    - os.boot
#  - require:
#      - salt: sync_modules_master
#      - salt: sync_minions
#restart_nodes:
#  salt.function:
#    - tgt: {{ allnodes|tojson }}
#    - tgt_type: list
#    - name: cmd.run
#    - arg:
#      - reboot
#    - require:
#      - salt: setup_prerequisites
#wait_for_restart:
#  salt.wait_for_event:
#    - name: salt/minion/*/start
#    - id_list: {{ allnodes|tojson }}
#    - require:
#      - salt: restart_nodes

setup_k3s_single_master:
  salt.state:
  - tgt: "k3sm1*"
  - highstate: True
  - pillar:
      kubernetes:
        nodes:
          masters: {{ masters|tojson }}
          workers: {{ workers|tojson }}
  - require:
      - salt: sync_modules_master
      - salt: sync_minions

setup_k3s_workers:
  salt.state:
  - tgt: "k3sw*"
  - highstate: True
  - pillar:
      kubernetes:
        nodes:
          masters: {{ masters|tojson }}
          workers: {{ workers|tojson }}
  - require:
      - salt: setup_k3s_single_master
