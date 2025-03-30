# add in CLI: pillar='{"kubernetes": {"nodes": {"masters": [k3sm1], "workers": [k3sw1]}}}'
{% set default_masters = salt.saltutil.runner('manage.up', tgt="k3sm*") %}
{% set default_workers = salt.saltutil.runner('manage.up', tgt="k3sw*") %}
{%- set masters = salt['pillar.get']('kubernetes:nodes:masters', default_masters) %}
{%- set workers = salt['pillar.get']('kubernetes:nodes:workers', default_workers) %}
{% set allnodes = [] %}
{% do allnodes.extend(masters) %}
{% do allnodes.extend(workers) %}

sync_modules_master:
  salt.runner:
  - name: saltutil.sync_all

sync_minions:
  salt.function:
  - tgt: "{{ allnodes|join(',') }}"
  - tgt_type: list
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
  - tgt: "{{ masters|first }}"
  - tgt_type: list
  - highstate: True
  - pillar:
      kubernetes:
        nodes:
          masters: {{ masters|tojson }}
          workers: {{ workers|tojson }}
  - require:
      - salt: sync_modules_master
      - salt: sync_minions

{%- if masters|length > 1 %}
setup_k3s_other_masters:
  salt.state:
  - tgt: "{{ masters[1:]|join(',') }}"
  - tgt_type: list
  - highstate: True
  - pillar:
      kubernetes:
        nodes:
          masters: {{ masters|tojson }}
          workers: {{ workers|tojson }}
  - require:
      - salt: setup_k3s_single_master
  - require_in:
      - salt: setup_k3s_workers
{%- endif %}

setup_k3s_workers:
  salt.state:
  - tgt: "{{ workers|join(',') }}"
  - tgt_type: list
  - highstate: True
  - pillar:
      kubernetes:
        nodes:
          masters: {{ masters|tojson }}
          workers: {{ workers|tojson }}
  - require:
      - salt: setup_k3s_single_master
