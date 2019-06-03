statreg:
  status.reg

keydel:
  key.timeout:
    - delete: 60
    - require:
      - status: statreg
