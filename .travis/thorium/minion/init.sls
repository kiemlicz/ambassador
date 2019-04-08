statreg:
  status.reg

keydel:
  key.timeout:
    - delete: 90
    - require:
      - status: statreg
