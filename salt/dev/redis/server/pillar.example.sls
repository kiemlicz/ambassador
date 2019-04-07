redis:
  setup_type: cluster # cluster, single
  port: 6379 #for single setup_type
  ip: 127.0.0.1 #for single setup_type
  total_slots: 16384
  config:
    source: salt://redis.conf
    dir: /var/lib/redis
    pid: /var/run/redis/redis-server.pid
    init: salt://redis.init
    init_location: /etc/init.d/redis-server
    service: redis-server
  replication_factor: 2
  instances:
    masters:
    - name: minionid
    - name: minionid_other
    - name: some_name_not_minion
    slaves:
    - name: minionidslave
      of_master: minionid
    map:
        minionid:
            ip: 1.2.3.4
            port: 1234
        minionid_other:
            ip: 1.2.3.5
            port: 1234
        some_name_not_minion:
            ip: 1.2.3.4
            port: 1236
        minionidslave:
            ip: 1.2.3.6
            port: 1235
---
redis:
  instances:
    masters:
    - name: pod1
    - name: pod2
    slaves:
    - name: pod3
      ofmaster: pod1
    - name: pod4
      ofmaster: pod2
---
redis:
  instances:
    map:
        pod1:
            ip: 127.0.0.1
            port: 6379
        pod2:
            ip: 127.0.0.1
            port: 6379
        pod3:
            ip: 127.0.0.1
            port: 6379
        pod4:
            ip: 127.0.0.1
            port: 6379
