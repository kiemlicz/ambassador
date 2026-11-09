{% from "zfs/map.jinja" import zfs with context %}

# Datasets of a missing pool are skipped (onlyif, result True), so highstate stays green until the pool is created.
# Directories are managed only on a mounted dataset, never on the underlying root filesystem
# (a non-empty mountpoint dir would block the later ZFS mount).
include:
  - zfs

{%- for dataset, conf in zfs.datasets.items() %}
{%- set pool = dataset.split('/')[0] %}
{%- set mounted = "zfs get -H -o value mounted " ~ dataset ~ " 2>/dev/null | grep -qx yes" %}
zfs_dataset_{{ dataset }}:
  zfs.filesystem_present:
    - name: {{ dataset }}
    - create_parent: True
{%- if conf.properties is defined %}
    - properties: {{ conf.properties | tojson }}
{%- endif %}
    - onlyif: zpool list -H -o name {{ pool }}
    - require:
      - sls: zfs

{#- path: explicit, own mountpoint, or inherited from the pool root mountpoint #}
{%- set pool_mp = zfs.pools.get(pool, {}).get('filesystem_properties', {}).get('mountpoint', '/' ~ pool) %}
{%- set path = conf.get('path') or conf.get('properties', {}).get('mountpoint') or (pool_mp ~ '/' ~ dataset.split('/', 1)[1]) %}
{%- if conf.user is defined or conf.group is defined or conf.mode is defined %}
zfs_dataset_{{ dataset }}_root:
  file.directory:
    - name: {{ path }}
    - user: {{ conf.get('user', 'root') }}
    - group: {{ conf.get('group', 'root') }}
    - mode: "{{ conf.get('mode', '0755') }}"
    - onlyif: {{ mounted }}
    - require:
      - zfs: zfs_dataset_{{ dataset }}
{%- endif %}

{%- for dir in conf.get('dirs', []) %}
zfs_dataset_{{ dataset }}_dir_{{ dir }}:
  file.directory:
    - name: {{ path }}/{{ dir }}
    - user: {{ conf.get('user', 'root') }}
    - group: {{ conf.get('group', 'root') }}
    - mode: "{{ conf.get('mode', '0755') }}"
    - makedirs: True
    - onlyif: {{ mounted }}
    - require:
      - zfs: zfs_dataset_{{ dataset }}
{%- endfor %}
{%- endfor %}