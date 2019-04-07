keepalived:
  service1:  &service1
    virtual_router_id: 11
    interface: eth0
    lvs_sync_daemon_interface: eth1
    advert_int: 1
    authentication:
      auth_type: PASS
      auth_pass: somepass
    virtual_ipaddress:
      - 10.10.253.99 dev eth0
  virtual_server: &virtual_server
    delay_loop: 6
    lb_algo: sh
    lb_kind: DR
    protocol: TCP
    quorum: 1
  real_server: &real_server
    weight: 1
    inhibit_on_failure: ""
    TCP_CHECK:
      connect_timeout: 3
      #real server port by default
  virtual_servers:
    "10.10.253.99 80":
      <<: *virtual_server
      real_servers:
        "192.168.1.20 80": *real_server
        "192.168.1.29 80": *real_server
  minion1:
    vrrp_instances:
      service1:
        <<: *service1
        state: MASTER
        priority: 100
  minion2:
    vrrp_instances:
      service1:
        <<:  *service1
        state: BACKUP
        priority: 50
