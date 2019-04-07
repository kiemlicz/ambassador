base:
  '*':
    - all
  'minion*.local':
    - base
    - pkgs_dev
    - one_user
    - orchestrate
  'salt-minion-*':
    - overrides
  'travis-*':
    - travis
