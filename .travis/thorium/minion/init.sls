statreg:
  status.reg

keydel:
  key.timeout:
    - delete: 30
    - require:
      - status: statreg
