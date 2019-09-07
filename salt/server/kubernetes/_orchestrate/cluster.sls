{% set masters = salt['pillar.get']('kubernetes:nodes:masters') %}

{% if masters|length < 1 %}
{{ raise('ERROR: at least one master must be specified') }}
{% endif %}

setup_first_master:
  salt.state:
  - tgt: "{{ masters|first }}"
  - sls:
    - docker
    - docker.events
    - kubernetes.master
  - saltenv: {{ saltenv }}
  - pillar: {{ pillar }}

{% if masters|length > 1 %}
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
{% endif %}

setup_workers:
  salt.state:
  - tgt: "{{ salt['pillar.get']('kubernetes:nodes:workers')|join(",") }}"
  - tgt_type: "list"
  - sls:
    - docker.events
    - kubernetes.worker
  - saltenv: {{ saltenv }}
  - pillar: {{ pillar }}
  - require:
      - salt: setup_master
