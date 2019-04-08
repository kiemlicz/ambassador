statreg:
  status.reg

keydel:
  key.timeout:
    - delete: 20
    - require:
      - status: statreg
