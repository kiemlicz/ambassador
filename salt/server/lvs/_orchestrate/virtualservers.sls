{%- set virtual_servers = salt.pillar.get('lvs:vs', []) %}
# if all virtual servers must be provisioned before proceeding then Thorium must be used to aggregate events first, then spawn this orchestration
virtual_servers_setup:
  salt.state:
    - tgt: {{ virtual_servers|join(",") }}
    - tgt_type: list
    - highstate: True
    - saltenv: server
