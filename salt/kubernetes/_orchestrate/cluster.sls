# these must be provided from CLI
{%- set masters_lb = salt['pillar.get']('kubernetes:nodes:masters-lb', []) %}
{%- set masters = salt['pillar.get']('kubernetes:nodes:masters', []) %}
{%- set workers = salt['pillar.get']('kubernetes:nodes:workers', []) %}
{%- if masters|length < 1 %}
{{ raise('ERROR: at least one master must be specified') }}
{%- endif %}
{%- if masters|length > 1 and masters_lb|length < 1 %}
{{ raise('ERROR: for multi-master setup load balancers must be specified') }}
{%- endif %}

sync_modules_master:
  salt.runner:
  - name: saltutil.sync_all

sync_modules_minions:
  salt.function:
  - name: saltutil.sync_all
  - tgt: "{{ (masters_lb+masters+workers)|join(',') }}"
  - tgt_type: list
  - kwarg:
      refresh: True

# LVS NAT
control_plane_load_balancers:
  salt.state:
    - tgt: "{{ masters_lb|join(',') }}"
    - tgt_type: list
    - sls:
      - keepalived
      - lvs.director

master_network_setup:
  salt.state:
    - tgt: "{{ masters|join(',') }}"
    - tgt_type: list
    - sls:
      - os.network
    - require:
        - salt: control_plane_load_balancers

master_network_setup_apply:
  salt.function:
    - tgt: "{{ masters|join(',') }}"
    - tgt_type: list
    - name: system.reboot
    - onchanges:
      - salt: master_network_setup

wait_for_masters_setup:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: {{ masters|tojson }}
    - onchanges:
      - salt: master_network_setup_apply

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/#steps-for-the-first-control-plane-node
setup_first_master:
  salt.state:
  - tgt: "{{ masters|first }}"
  - sls:
    - docker
    - kubernetes.master
  - pillar: {{ pillar }}
  - require:
    - salt: wait_for_masters_setup

{%- if masters|length > 1 %}
setup_masters:
  salt.state:
  - tgt: "{{ masters[1:]|join(',') }}"
  - tgt_type: list
  - sls:
    - docker
    - kubernetes.master
  - pillar: {{ pillar }}
  - require:
    - salt: setup_first_master
  - require_in:
    - salt: setup_workers
{%- endif %}

setup_workers:
  salt.state:
  - tgt: "{{ workers|join(",") }}"
  - tgt_type: list
  - sls:
    - kubernetes.worker
  - pillar: {{ pillar }}
  - require:
      - salt: setup_first_master
