# LVS
Configures Keepalived and LVS.

Due to complex setup the Real Servers must be provisioned first, then once they upload thier IP addresses to [Salt Mine](https://docs.saltstack.com/en/latest/topics/mine/index.html) the Virtual Servers setup may start.  
The best way to achieve this is to use Salt Orchestration.

## Available states
 - [`lvs.director`](#lvsdirector)
 - [`lvs.realserver`](#lvsrealserver)

## Usage
Some prerequisites must be met first:
- _Salt Minion_ configuration must contain:
```
mine_functions:
  real_server_ip:
  - mine_function: network.ip_addrs
grains:
  lvs:
    rs: True # for Real Servers
    # vs: True # for Virtual Servers
```
1. Setup pillar:
#### **`top.sls`**
```
base:
  'keepalived*':
    - virtualserver
  'vm*':
    - realserver
```
#### **`realserver.sls`**
```
{%- set ip = salt.filters.ips_in_subnet(grains['ipv4'], cidr="192.168.1.0/24")|first %}
{%- set interface = salt.filters.ifc_for_ip(ip, grains['ip_interfaces']) %}
{%- set virtual_ips = ["192.168.1.2"] %}

network:
  # for highstate
  enabled: False
  interfaces:
{%- if not interface is equalto("br0") %}
    br0:
      enabled: True
      type: bridge
      ports: {{ interface }}
      proto: dhcp
      use:
        - network: {{ interface }}
      require:
        - network: {{ interface }}
    {{ interface }}:
      type: eth
      enabled: False
      noifupdown: True
      proto: manual
{%- endif %}
    lo:
      enabled: True
      type: eth
      proto: loopback
      up_cmds:
        {%- for vip in virtual_ips %}
        - ip addr add {{ vip }}/32 dev $IFACE label $IFACE:{{ loop.index0 }}
        {%- endfor %}
      down_cmds:
        {%- for vip in virtual_ips %}
        - ip addr del {{ vip }}/32 dev $IFACE label $IFACE:{{ loop.index0 }}
        {%- endfor %}

lxc:
  containers:
    keepalived-{{ grains['host'] }}:
      running: True
      network_profile:
        eth0:
          link: br0
          type: veth
          flags: up
      template: debian
      options:
        release: buster
        arch: amd64
      bootstrap_args: "-x python3"
      config:
        # LVS Virtual Server marker
        grains:
          lvs:
            vs: True

pkgs:
  os_packages:
    - ipvsadm
    - apache2

kernel_modules:
  present:
    - name: ip_vs
      persist: True
```
#### **`virtualserver.sls`**
```
{%- set ip = salt.filters.ips_in_subnet(grains['ipv4'], cidr="192.168.1.0/24")|first %}
{%- set interface = salt.filters.ifc_for_ip(ip, grains['ip_interfaces']) %}
{%- set real_servers = salt.saltutil.runner('mine.get', tgt='vm*', fun="real_server_ip")|default({}) %}
{%- if not real_servers %}
{{ raise("Real servers not found") }}
{%- endif %}
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
```
2. `salt-run state.orchestrate lvs._orchestrate.realservers saltenv=server`
3. `salt-run state.orchestrate lvs._orchestrate.virtualservers saltenv=server` However if Real Servers spawns LXC containers this step can be run from [LXC reactor](https://github.com/kiemlicz/ambassador/blob/master/salt/base/lxc/_reactor/lxc.sls)

### `lvs.director`
### `lvs.realserver`
