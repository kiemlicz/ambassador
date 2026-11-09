{% from "zfs/map.jinja" import zfs with context %}
{% from "_common/util.jinja" import retry with context %}

zfs_apt_preferences:
{%- if zfs.get('preferences_pin') %}
  file.managed:
    - name: {{ zfs.preferences_file }}
    - contents: |
        Package: {{ zfs.preferences_package }}
        Pin: {{ zfs.preferences_pin }}
        Pin-Priority: {{ zfs.preferences_priority }}
{%- else %}
  file.absent:
    - name: {{ zfs.preferences_file }}
{%- endif %}

zfs_pkgs:
  pkg.latest:
    - pkgs: {{ zfs.pkgs | tojson }}
{%- if zfs.get('fromrepo') %}
    - fromrepo: {{ zfs.fromrepo }}
{%- endif %}
    - refresh: True
    - reload_modules: True # zpool/zfs execution modules load only when binaries exist
{{ retry(attempts=2, interval=30) | indent(4) }}
    - require:
      - file: zfs_apt_preferences

zfs_dkms_built:
  test.fail_without_changes:
    - name: "ZFS DKMS module is not built for the running kernel, check: dkms status -m zfs"
    - unless: dkms status -m zfs -k "$(uname -r)" | grep -q installed
    - require:
      - pkg: zfs_pkgs

zfs_module_options:
  file.managed:
    - name: {{ zfs.modprobe_conf }}
    - contents: |
{%- for param, value in zfs.module_params.items() %}
        options zfs {{ param }}={{ value }}
{%- endfor %}
    - require_in:
      - pkg: zfs_pkgs # package install may load the module; options must exist first

zfs_module:
  kmod.present:
    - name: zfs
    - persist: True
    - require:
      - test: zfs_dkms_built
      - file: zfs_module_options

# Salt >= 3008 core has no zfs/zpool modules, they live in the saltext.zfs extension
zfs_saltext:
  cmd.run:
    - name: salt-pip install {{ zfs.saltext }}
    - unless: salt-pip show {{ zfs.saltext }}

# zfs/zpool modules load only when the zfs_support grain is true (/sys/module/zfs + zpool binary):
# reload_grains/force_reload_modules make them usable later in this run (zfs.pools/zfs.datasets),
# saltutil.refresh_grains persists the grain in the minion for later runs
zfs_salt_refresh:
  module.run:
    - saltutil.refresh_grains:
      - refresh_pillar: False
    - reload_grains: True
    - force_reload_modules: True
    - require:
      - kmod: zfs_module
      - cmd: zfs_saltext

{%- for param, value in zfs.module_params.items() %}
zfs_module_param_{{ param }}:
  cmd.run:
    - name: echo {{ value }} > /sys/module/zfs/parameters/{{ param }}
    - unless: test "$(cat /sys/module/zfs/parameters/{{ param }})" = "{{ value }}"
    - require:
      - kmod: zfs_module
{%- endfor %}

zfs_zed_config:
  file.keyvalue:
    - name: {{ zfs.zed_rc }}
    - key_values: {{ zfs.zed | tojson }}
    - separator: "="
    - uncomment: "#"
    - append_if_not_found: True
    - require:
      - pkg: zfs_pkgs

zfs_services:
  service.enabled:
    - names: {{ zfs.services | tojson }}
    - require:
      - kmod: zfs_module

zfs_zed_running:
  service.running:
    - name: zfs-zed
    - enable: True
    - watch:
      - file: zfs_zed_config
    - require:
      - kmod: zfs_module

zfs-notification:
  test.succeed_without_changes:
    - name: ZFS setup completed
    - require:
      - service: zfs_services
      - service: zfs_zed_running
      - module: zfs_salt_refresh