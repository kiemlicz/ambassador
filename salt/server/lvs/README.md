# LVS

## Available states
 - [`lvs.director`](#lvsdirector)
 - [`lvs.realserver`](#lvsrealserver)

## Usage
Full run requires reactor setup since first Real Servers must be provisioned, then continue with Virtual Servers.

`salt-run state.orchestrate lvs._orchestrate.realservers saltenv=server pillar="{'lvs': {'rs': ['vm1', 'vm2']}}"`
 
### `lvs.director`
### `lvs.realserver`
