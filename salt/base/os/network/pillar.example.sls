---
network:
  enabled: False  # don't manage network interfaces via `os` state
---
network:
  enabled: True
  interfaces:
    eth0:
      type: eth
    eth1:
      type: eth
      require:
        - network: eth0
---
# example pillar that setup bridge interface instead of existsing eth
{%- set ip = salt.filters.ips_in_subnet(grains['ipv4'], cidr="127.0.0.0/24")|first %}
{%- set interface = salt.filters.ifc_for_ip(ip, grains['ip_interfaces']) %}
network:
  # in this case must be run from `salt-run state.orchestrate lvs._orchestrate saltenv=server`
  enabled: False
{%- if not interface is equalto("br0") %}
  interfaces:
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
      # in order not to lose connection to minion when eth is the only network adapter
      noifupdown: True
      enabled: False
      proto: manual
{%- endif %}