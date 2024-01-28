sync_modules_master:
  salt.runner:
  - name: saltutil.sync_all

setup_k3s_single_master:
  salt.state:
  - tgt: "k3sm1*"
  - highstate: True
  - pillar:
      kubernetes:
        nodes:
          masters: {{ salt.saltutil.runner('manage.up', tgt="k3sm*") }}
          workers: {{ salt.saltutil.runner('manage.up', tgt="k3sw*") }}
  - require:
    - salt: sync_modules_master

setup_k3s_workers:
  salt.state:
  - tgt: "k3sw*"
  - highstate: True
  - pillar:
      kubernetes:
        nodes:
          masters: {{ salt.saltutil.runner('manage.up', tgt="k3sm*") }}
          workers: {{ salt.saltutil.runner('manage.up', tgt="k3sw*") }}
  - require:
      - salt: setup_k3s_single_master
