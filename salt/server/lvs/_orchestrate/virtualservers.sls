# if all virtual servers must be provisioned before proceeding then Thorium must be used to aggregate events first, then spawn this orchestration
virtual_servers_setup:
  salt.state:
    - tgt: "G@lvs:vs:True and {{ salt.pillar.get('lvs:vs', '')|join(',') }}" 
    - tgt_type: compound
    - highstate: True
    - saltenv: server
