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
---
{%- set interface = "eth0" %}
{%- set real_servers = {'vm1': ["192.168.1.4", "192.168.1.5"]} %}
{%- set virtual_ips = ["192.168.1.2"] %} 
keepalived:
  configs:
    - location: /etc/keepalived/keepalived.d/instances.conf
      contents: |
        vrrp_instance apache {
          advert_int 1
          authentication {
            auth_pass somepass
            auth_type PASS
          }
          garp_master_refresh 30
          interface {{ interface }}
          {%- if grains['id'] == 'keepalived-vm1' %}
          priority 100
          state MASTER
          {%- else %}
          priority 50
          state BACKUP
          {%- endif %}
          virtual_ipaddress {
            {%- for vip in virtual_ips %}
            {{ vip }} dev {{ interface }} scope global
            {%- endfor %}
          }
          virtual_router_id 1
        }
    - location: /etc/keepalived/keepalived.d/virtual_server.conf
      contents: |
        {%- for vip in virtual_ips %}
          virtual_server {{ vip }} 80 {
            delay_loop 6
            lb_algo sh            
            lb_kind DR
            sh-fallback
            protocol TCP
            quorum 1
            
            {%- for minion, addrs in real_servers.items() %}
            real_server {{ addrs|first }} 80 {
                TCP_CHECK {
                  connect_timeout 3
                }
                inhibit_on_failure 
                weight 1
            }
            {%- endfor %}
          }
        {%- endfor %}
    - location: /etc/keepalived/keepalived.conf
      contents: |
        include /etc/keepalived/keepalived.d/*.conf
    - location: /etc/keepalived/keepalived.d/global_defs.conf
      contents: |
        global_defs {
            lvs_sync_daemon {{ interface }} internal
            script_user keepalived_script
            enable_script_security
            vrrp_garp_master_refresh 30
        }
