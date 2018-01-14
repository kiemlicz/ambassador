minions:
  - minion1.local
  - minion2.local
  - minion3.local

redis:
  masters:
    - host_id: minion1.local
      host: minion1.local
      port: 6379
    - host_id: minion2.local
      host: minion2.local
      port: 6379
    - host_id: minion3.local
      host: minion3.local
      port: 6379
  slaves:
    - host_id: minion1.local
      master_host: minion2.local
      master_port: 6379
      host: minion1.local
      port: 6380
    - host_id: minion2.local
      master_host: minion3.local
      master_port: 6379
      host: minion2.local
      port: 6380
    - host_id: minion3.local
      master_host: minion1.local
      master_port: 6379
      host: minion3.local
      port: 6380
