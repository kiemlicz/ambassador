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
# fixme this is stupid, test only cfg using dedicated runner, move all of these to pillar.example.sls
# come up with a way to combine pillar.example.sls'es into one pillar passed to saltcheck run