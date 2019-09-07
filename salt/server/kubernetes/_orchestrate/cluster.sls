setup_master:
  salt.state:
  - tgt: "{{ salt['pillar.get']('kubernetes:nodes:masters')|join(",") }}"
  - tgt_type: "list"
  - sls:
    - docker
    - docker.events
    - kubernetes.master
  - saltenv: {{ saltenv }}
  - pillar: {{ pillar }}

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
