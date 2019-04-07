setup_master:
  salt.state:
  - tgt: "kubernetes:master:True"
  - tgt_type: "grain"
  - sls:
    - docker
    - docker.events
    - kubernetes.master
  - saltenv: {{ saltenv }}

setup_workers:
  salt.state:
  - tgt: "kubernetes:worker:True"
  - tgt_type: "grain"
  - sls:
    - docker.events
    - kubernetes.worker
  - saltenv: {{ saltenv }}
  - require:
      - salt: setup_master
