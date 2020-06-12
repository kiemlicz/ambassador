{%- set masters = salt['pillar.get']('kubernetes:nodes:masters', []) %}
{%- set workers = salt['pillar.get']('kubernetes:nodes:workers', []) %}
{%- if masters|length < 1 %}
{{ raise('ERROR: at least one master must be specified') }}
{%- endif %}

sync_modules_master:
  salt.runner:
  - name: saltutil.sync_all

sync_modules_minions:
  salt.function:
  - name: saltutil.sync_all
  - tgt: "{{ (masters+workers)|join(',') }}"
  - tgt_type: list
  - kwarg:
      refresh: True

setup_first_master:
  salt.state:
  - tgt: "{{ masters|first }}"
  - sls:
    - docker
    - docker.events
    - kubernetes.master
  - saltenv: {{ saltenv }}
  - pillar: {{ pillar }}
  - require:
    - salt: sync_modules_master
    - salt: sync_modules_minions

{%- if masters|length > 1 %}
setup_masters:
  salt.state:
  - tgt: "{{ masters[1:] }}"
  - sls:
    - docker
    - docker.events
    - kubernetes.master
  - saltenv: {{ saltenv }}
  - pillar: {{ pillar }}
  - require_in:
    - salt: setup_workers
{%- endif %}

setup_workers:
  salt.state:
  - tgt: "{{ workers|join(",") }}"
  - tgt_type: "list"
  - sls:
    - docker.events
    - kubernetes.worker
  - saltenv: {{ saltenv }}
  - pillar: {{ pillar }}
  - require:
      - salt: setup_first_master
