# LVS
Confiures Keepalived and LVS.

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

```
#### **`virtualserver.sls`**
```

```
2. `salt-run state.orchestrate lvs._orchestrate.realservers saltenv=server`
3. `salt-run state.orchestrate lvs._orchestrate.virtualservers saltenv=server` However if Real Servers spawns LXC containers this step can be run from [LXC reactor](#salt/base/lxc/_reactor/lxc.sls)

### `lvs.director`
### `lvs.realserver`
