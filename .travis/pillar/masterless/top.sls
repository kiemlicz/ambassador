base:
  '*':
    - all
  'base-host':
    - base
    - pkgs_base
    - one_user
  'gui-host':
    - base
    - repositories
    - pkgs_gui
    - one_user
  'dev-host':
    - base
    - pkgs_dev
    - repositories_dev
    - one_user
