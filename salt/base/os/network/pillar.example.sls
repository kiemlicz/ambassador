network:
  enabled: True
  interfaces:
    eth0:
      type: eth
    eth1:
      type: eth
      require:
        - network: eth0
