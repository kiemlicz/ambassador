{% from "zfs/map.jinja" import zfs with context %}

# Pool creation is destructive. Never part of highstate.
# A missing pool is created only with one-shot pillar flag, e.g.:
#   salt <minion> state.apply zfs.pools pillar='{"zfs": {"pools": {"tank": {"create": true}}}}'
# Without the flag the layout isn't passed: an existing pool gets its properties enforced,
# a missing one fails with "no (valid) layout specified for creation".
# Decided at runtime (no render-time zpool calls), so it works in the same run that installs ZFS.
# saltext.zfs 1.0.0 can't change a property to "none" (runs `zpool set <prop> <pool>` without a value),
# set it once by hand (e.g. `zpool set cachefile=none tank`); afterwards the state compares it fine.

include:
  - zfs

{%- for pool, conf in zfs.pools.items() %}
zfs_pool_{{ pool }}:
  zpool.present:
    - name: {{ pool }}
    - config:
        import: True
        force: False
{%- if conf.properties is defined %}
    - properties: {{ conf.properties | tojson }}
{%- endif %}
{%- if conf.get('create', False) %}
{%- if conf.filesystem_properties is defined %}
    - filesystem_properties: {{ conf.filesystem_properties | tojson }}
{%- endif %}
    - layout: {{ conf.layout | tojson }}
{%- endif %}
    - require:
      - sls: zfs
{%- endfor %}