# Redis
_State Tree_ for all redis related configuration

### Available states
 - [`redis.client`](https://github.com/kiemlicz/envoy/tree/master/salt/dev/redis#redis.client) installs `redis-cli` utility from OS repository
 - [`redis.server`](https://github.com/kiemlicz/envoy/tree/master/salt/dev/redis#redis.server) installs `redis-server` and configures it

#### `redis.client`
Installs Redis client package from the OS repository
```
redis:
  client:
    pkg_name: redis-client
```

#### `redis.server`
Installs Redis server package from the OS repository
```
redis:
  setup_type: cluster           # cluster, single
  port: 6379                    # for single setup_type
  ip: 127.0.0.1                 # for single setup_type
  total_slots: 16384            # constant magic
  config:
    source: salt://redis.conf
    dir: /var/lib/redis
    pid: /var/run/redis/redis-server.pid
    init: salt://redis.init
    init_location: /etc/init.d/redis-server
    service: redis-server
``` 
