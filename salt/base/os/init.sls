{%- from "os/network/map.jinja" import network with context %}
include:
{%- if network.enabled %}
# included only upon explicit request
  - os.network
{%- endif %}
  - os.repositories
  - os.mounts
  - os.hosts
  - os.locale
  - os.groups
  - os.pkgs
  - os.modules
  - os.pkgs.scripts
  - os.services

os-notification:
  test.show_notification:
    - name: OS basic setup completed
    - text: "OS basic setup completed"
