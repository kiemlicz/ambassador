setup_master:
  salt.state:
  - tgt: "{{ pillar['kubernetes']['nodes']['masters'] }}"
  - tgt_type: "compound"
  - sls:
    - docker
    - docker.events
    - kubernetes.master
  - saltenv: {{ saltenv }}

setup_workers:
  salt.state:
  - tgt: "{{ pillar['kubernetes']['nodes']['workers'] }}"
  - tgt_type: "compound"
  - sls:
    - docker.events
    - kubernetes.worker
  - saltenv: {{ saltenv }}
  - require:
      - salt: setup_master
