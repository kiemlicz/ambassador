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
      of_master:
        id: minion2.local
        port: 6379
      port: 6380
    - id: minion2.local
      of_master:
        id: minion3.local
        port: 6379
      port: 6380
    - id: minion3.local
      of_master:
        id: minion1.local
        port: 6379
      port: 6380

mongodb:
  setup_type: cluster
  install_type: repo
  shards: []
  replicas:
    - id: minion1.local
      master: "True"
      replica_name: "testing"
      port: 28018
    - id: minion1.local
      replica_name: "testing"
      port: 28019
    - id: minion2.local
      replica_name: "testing"
      port: 28018
    - id: minion3.local
      replica_name: "testing"
      port: 28018
