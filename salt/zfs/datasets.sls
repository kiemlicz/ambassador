{% from "zfs/map.jinja" import zfs with context %}

# No render-time zfs calls: a missing pool makes zfs.filesystem_present fail at runtime
include:
  - zfs

{%- for dataset, conf in zfs.datasets.items() %}
{%- set pool = dataset.split('/')[0] %}
zfs_dataset_{{ dataset }}:
  zfs.filesystem_present:
    - name: {{ dataset }}
    - create_parent: True
{%- if conf.properties is defined %}
    - properties: {{ conf.properties | tojson }}
{%- endif %}
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
    - require:
      - zfs: zfs_dataset_{{ dataset }}
{%- endfor %}
{%- endfor %}
