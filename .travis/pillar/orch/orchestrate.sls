minions:
  - minion1.local
  - minion2.local
  - minion3.local

redis:
  setup_type: cluster
  masters:
    - name: master1
      port: 6379
    - name: master2
      port: 6379
    - name: master3
      port: 6379
  slaves:
    - name: slave1
      of_master: master2
      port: 6380
    - name: slave2
      of_master: master3
      port: 6380
    - name: slave3
      of_master: master1
      port: 6380

mongodb:
  setup_type: cluster
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
