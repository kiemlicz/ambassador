{%- from "os/network/map.jinja" import network with context %}
include:
{%- if network.enabled %}
# included only upon explicit request
  - os.network
{%- endif %}
  - os.repositories
  - os.udev
  - os.mounts
  - os.lvm
  - os.hosts
  - os.locale
  - os.groups
  - os.pkgs
  - os.sysctl
  - os.modules
  - os.pkgs.scripts
  - os.services

os-notification:
  test.succeed_without_changes:
    - name: OS basic setup completed
