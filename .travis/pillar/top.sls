base:
  '*':
    - base
    - pkgs_base
    - one_user
gui:
  '*':
    - base
    - pkgs_gui
    - one_user
dev:
  '*':
    - base
    - pkgs_dev
    - one_user
orch:
  '*':
    - base
    - pkgs_dev
    - one_user
    - orchestrate
empty:
  '*':
    - empty
