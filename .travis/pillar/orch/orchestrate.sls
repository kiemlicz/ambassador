minions:
  - minion1.local
  - minion2.local
  - minion3.local

redis:
  setup_type: cluster
  install_type: repo
  masters:
    - id: minion1.local
      port: 6379
    - id: minion2.local
      port: 6379
    - id: minion3.local
      port: 6379
  slaves:
    - id: minion1.local
      master_id: minion2.local
      master_port: 6379
      port: 6380
    - id: minion2.local
      master_id: minion3.local
      master_port: 6379
      port: 6380
    - id: minion3.local
      master_id: minion1.local
      master_port: 6379
      port: 6380

mongodb:
  setup_type: cluster
  install_type: repo
  shards: []
  replicas:
    - host_id: minion1.local
      master: True
      replica_name: "testing"
      host: minion1.local
      port: 28018
    - host_id: minion1.local
      replica_name: "testing"
      host: minion1.local
      port: 28019
    - host_id: minion2.local
      replica_name: "testing"
      host: minion2.local
      port: 28018
    - host_id: minion3.local
      replica_name: "testing"
      host: minion3.local
      port: 28018
