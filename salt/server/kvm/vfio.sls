{% from "kvm/map.jinja" import kvm with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}

grub_d_directory:
  file.directory:
    - name: /etc/default/grub.d
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

{% for config in kvm.vfio.configs %}
vfio_{{ config.name }}:
  file_ext.managed:
    - name: {{ config.name }}
{%- if config.contents is defined %}
    - contents: {{ config.contents | yaml_encode }}
{%- elif config.source is defined %}
    - source: {{ config.source }}
{%- endif %}
    - makedirs: True
    - skip_verify: True
    - require:
      - file: grub_d_directory
    - onchanges_in:
      - cmd: update_grub
      - cmd: update_initramfs
{%- endfor %}

update_grub:
  cmd.run:
    - name: {{ kvm.vfio.grub_update_cmd }}

update_initramfs:
  cmd.run:
    - name: {{ kvm.vfio.initramfs_update_cmd }}
